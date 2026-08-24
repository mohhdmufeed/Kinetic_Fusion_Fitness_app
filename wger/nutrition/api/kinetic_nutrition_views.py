# -*- coding: utf-8 -*-
from datetime import timedelta
from django.db.models import Q, Case, When, IntegerField
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema, OpenApiParameter

from wger.core.models.admin import AdminAuditLog
from wger.nutrition.models.kinetic_nutrition import KineticIngredient, KineticDiaryEntry
from wger.nutrition.food_seed import ensure_starter_foods_seeded
from wger.core.api.admin_permissions import IsSuperAdmin


def get_client_ip(request):
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        return x_forwarded_for.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR', '127.0.0.1')


def calculate_macros_pure(ingredient: KineticIngredient, quantity_g: float) -> dict:
    """
    Pure weight-based mathematical calculation:
    actual_value = (stored_value_per_100g / 100) * entered_grams
    """
    multiplier = quantity_g / 100.0
    return {
        "ingredient": ingredient.name,
        "quantity_g": round(quantity_g, 2),
        "calories_kcal": int(round((ingredient.calories_kcal * multiplier) + 1e-9)),
        "protein_g": round(ingredient.protein_g * multiplier, 1),
        "carbs_g": round(ingredient.carbs_g * multiplier, 1),
        "fat_g": round(ingredient.fat_g * multiplier, 1),
        "fiber_g": round(ingredient.fiber_g * multiplier, 1),
        "sugar_g": round(ingredient.sugar_g * multiplier, 1),
        "sodium_mg": int(round((ingredient.sodium_mg * multiplier) + 1e-9)),
    }


class NutritionSearchAPIView(APIView):
    """
    Ranked multi-tier search for ingredients against the CLOSED admin-curated library.
    Zero external API fallbacks.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Search Closed Ingredient Library",
        description="Search curated food database with exact/prefix ranking and user logging frequency boost.",
        parameters=[
            OpenApiParameter("q", type=str, description="Search query string (e.g. 'chicken breast' or 'banana')"),
        ],
        tags=["Nutrition & Food Logging"]
    )
    def get(self, request):
        ensure_starter_foods_seeded()
        user = request.user
        query_str = request.query_params.get('q', '').strip()

        if not query_str:
            qs = KineticIngredient.objects.filter(verified=True)[:30]
        else:
            user_fav_ids = list(
                KineticDiaryEntry.objects.filter(user=user)
                .values_list('ingredient_id', flat=True)
                .distinct()
            )

            qs = KineticIngredient.objects.filter(
                verified=True,
                name__icontains=query_str,
            ).annotate(
                exact_match=Case(
                    When(name__iexact=query_str, then=1),
                    default=0,
                    output_field=IntegerField(),
                ),
                prefix_match=Case(
                    When(name__istartswith=query_str, then=1),
                    default=0,
                    output_field=IntegerField(),
                ),
                user_frequent=Case(
                    When(id__in=user_fav_ids, then=1),
                    default=0,
                    output_field=IntegerField(),
                ),
            ).order_by('-exact_match', '-user_frequent', '-prefix_match', 'name')[:30]

        results = [
            {
                "id": ing.id,
                "name": ing.name,
                "category": ing.category,
                "calories_kcal": round(ing.calories_kcal),
                "protein_g": round(ing.protein_g, 1),
                "carbs_g": round(ing.carbs_g, 1),
                "fat_g": round(ing.fat_g, 1),
                "fiber_g": round(ing.fiber_g, 1),
                "sugar_g": round(ing.sugar_g, 1),
                "sodium_mg": round(ing.sodium_mg),
                "unit": "100g",
            }
            for ing in qs
        ]

        return Response({
            "count": len(results),
            "results": results,
        }, status=status.HTTP_200_OK)


class NutritionLookupAPIView(APIView):
    """
    Pure weight-based (grams only) macro calculation.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Calculate Exact Grams Nutrition",
        description="Calculates exact macros for entered gram weight from canonical 100g base.",
        tags=["Nutrition & Food Logging"]
    )
    def post(self, request):
        ensure_starter_foods_seeded()
        ingredient_id = request.data.get('ingredient_id')
        quantity_g = float(request.data.get('quantity_g', request.data.get('quantity', 100.0)))

        try:
            ingredient = KineticIngredient.objects.get(pk=ingredient_id, verified=True)
        except KineticIngredient.DoesNotExist:
            return Response({"detail": "Ingredient not found in closed library."}, status=status.HTTP_404_NOT_FOUND)

        calc = calculate_macros_pure(ingredient, quantity_g)
        calc["ingredient_id"] = ingredient.id
        return Response(calc, status=status.HTTP_200_OK)


class BarcodeLookupAPIView(APIView):
    """
    Looks up a food product by its barcode (EAN-13, EAN-8, UPC-A).
    Flow:
    1. Check local KineticIngredient database (matching barcode).
    2. Check Ingredient model (matching code).
    3. Query Open Food Facts external API if not in local database.
    4. Cache result server-side in KineticIngredient for instant subsequent lookups.
    5. Returns exact Module 11 per-100g schema.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Barcode Food Lookup (Open Food Facts)",
        description="Looks up food by barcode with server-side caching and Open Food Facts fallback.",
        parameters=[
            OpenApiParameter("code", type=str, description="Product barcode (e.g. 737628064502 or 3017620422003)"),
        ],
        tags=["Nutrition & Food Logging"]
    )
    def get(self, request):
        code = request.query_params.get('code', '').strip()
        return self._lookup_barcode(code)

    def post(self, request):
        code = str(request.data.get('code', request.data.get('barcode', ''))).strip()
        return self._lookup_barcode(code)

    def _lookup_barcode(self, code: str):
        if not code:
            return Response(
                {"detail": "Barcode parameter 'code' is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        ensure_starter_foods_seeded()

        # 1. Tier 1: Check KineticIngredient by barcode
        k_ing = KineticIngredient.objects.filter(barcode=code, verified=True).first()
        if k_ing:
            return Response(self._serialize_kinetic_ingredient(k_ing), status=status.HTTP_200_OK)

        # 2. Tier 2: Check Ingredient by code
        from wger.nutrition.models import Ingredient
        ing = Ingredient.objects.filter(code=code).first()
        if ing:
            # Promote/cache to KineticIngredient
            k_ing = KineticIngredient.objects.create(
                name=ing.name,
                category=ing.category.name if ing.category else 'General',
                brand=ing.brand or '',
                barcode=code,
                calories_kcal=float(ing.energy),
                protein_g=float(ing.protein),
                carbs_g=float(ing.carbohydrates),
                fat_g=float(ing.fat),
                fiber_g=float(ing.fiber or 0.0),
                sugar_g=float(ing.carbohydrates_sugar or 0.0),
                sodium_mg=float(ing.sodium or 0.0),
                source='open_food_facts',
                verified=True,
            )
            return Response(self._serialize_kinetic_ingredient(k_ing), status=status.HTTP_200_OK)

        # 3. Tier 3: Fetch from Open Food Facts API
        try:
            fetched_ing = Ingredient.fetch_ingredient_from_off(code)
            if fetched_ing:
                k_ing = KineticIngredient.objects.create(
                    name=fetched_ing.name,
                    category=fetched_ing.category.name if fetched_ing.category else 'Packaged Food',
                    brand=fetched_ing.brand or '',
                    barcode=code,
                    calories_kcal=float(fetched_ing.energy),
                    protein_g=float(fetched_ing.protein),
                    carbs_g=float(fetched_ing.carbohydrates),
                    fat_g=float(fetched_ing.fat),
                    fiber_g=float(fetched_ing.fiber or 0.0),
                    sugar_g=float(fetched_ing.carbohydrates_sugar or 0.0),
                    sodium_mg=float(fetched_ing.sodium or 0.0),
                    source='open_food_facts',
                    verified=True,
                )
                return Response(self._serialize_kinetic_ingredient(k_ing), status=status.HTTP_200_OK)
        except Exception:
            pass

        return Response(
            {
                "detail": f"Product not found for barcode '{code}'.",
                "barcode": code,
                "not_found": True,
            },
            status=status.HTTP_404_NOT_FOUND,
        )

    def _serialize_kinetic_ingredient(self, ing: KineticIngredient) -> dict:
        return {
            "id": ing.id,
            "name": ing.name,
            "brand": ing.brand or "",
            "barcode": ing.barcode or "",
            "category": ing.category,
            "calories_kcal": round(ing.calories_kcal),
            "protein_g": round(ing.protein_g, 1),
            "carbs_g": round(ing.carbs_g, 1),
            "fat_g": round(ing.fat_g, 1),
            "fiber_g": round(ing.fiber_g, 1),
            "sugar_g": round(ing.sugar_g, 1),
            "sodium_mg": round(ing.sodium_mg),
            "unit": "100g",
            "source": ing.source,
        }


class NutritionDiaryListCreateAPIView(APIView):
    """
    Athlete meal logging & day-at-a-glance diary breakdown with live target progress.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Get Daily Food Diary",
        description="Returns meals grouped by category with running macro totals vs user target.",
        parameters=[
            OpenApiParameter("date", type=str, description="Target date in YYYY-MM-DD format"),
        ],
        tags=["Nutrition & Food Logging"]
    )
    def get(self, request):
        user = request.user
        date_str = request.query_params.get('date')
        target_date = parse_date(date_str) if date_str else timezone.now().date()

        entries = (
            KineticDiaryEntry.objects.filter(user=user, logged_at__date=target_date)
            .select_related('ingredient')
            .order_by('logged_at')
        )

        meals = {
            "breakfast": {"items": [], "subtotal_kcal": 0, "subtotal_protein": 0.0, "subtotal_carbs": 0.0, "subtotal_fat": 0.0},
            "lunch": {"items": [], "subtotal_kcal": 0, "subtotal_protein": 0.0, "subtotal_carbs": 0.0, "subtotal_fat": 0.0},
            "dinner": {"items": [], "subtotal_kcal": 0, "subtotal_protein": 0.0, "subtotal_carbs": 0.0, "subtotal_fat": 0.0},
            "snack": {"items": [], "subtotal_kcal": 0, "subtotal_protein": 0.0, "subtotal_carbs": 0.0, "subtotal_fat": 0.0},
        }

        total_kcal = 0
        total_protein = 0.0
        total_carbs = 0.0
        total_fat = 0.0
        total_fiber = 0.0
        total_sugar = 0.0
        total_sodium = 0.0

        for entry in entries:
            ing = entry.ingredient
            calc = calculate_macros_pure(ing, entry.quantity_g)
            item_data = {
                "id": entry.id,
                "client_uuid": str(entry.client_uuid),
                "ingredient_id": ing.id,
                "ingredient_name": ing.name,
                "category": ing.category,
                "quantity_g": entry.quantity_g,
                "meal": entry.meal,
                "calories_kcal": calc["calories_kcal"],
                "protein_g": calc["protein_g"],
                "carbs_g": calc["carbs_g"],
                "fat_g": calc["fat_g"],
                "fiber_g": calc["fiber_g"],
                "sugar_g": calc["sugar_g"],
                "sodium_mg": calc["sodium_mg"],
                "logged_at": entry.logged_at.isoformat(),
            }

            meal_key = entry.meal if entry.meal in meals else "snack"
            meals[meal_key]["items"].append(item_data)
            meals[meal_key]["subtotal_kcal"] += calc["calories_kcal"]
            meals[meal_key]["subtotal_protein"] = round(meals[meal_key]["subtotal_protein"] + calc["protein_g"], 1)
            meals[meal_key]["subtotal_carbs"] = round(meals[meal_key]["subtotal_carbs"] + calc["carbs_g"], 1)
            meals[meal_key]["subtotal_fat"] = round(meals[meal_key]["subtotal_fat"] + calc["fat_g"], 1)

            total_kcal += calc["calories_kcal"]
            total_protein = round(total_protein + calc["protein_g"], 1)
            total_carbs = round(total_carbs + calc["carbs_g"], 1)
            total_fat = round(total_fat + calc["fat_g"], 1)
            total_fiber = round(total_fiber + calc["fiber_g"], 1)
            total_sugar = round(total_sugar + calc["sugar_g"], 1)
            total_sodium += calc["sodium_mg"]

        target_kcal = 2400
        target_protein = 160.0
        target_carbs = 260.0
        target_fat = 75.0

        return Response({
            "date": target_date.isoformat(),
            "meals": meals,
            "totals": {
                "calories_kcal": total_kcal,
                "protein_g": total_protein,
                "carbs_g": total_carbs,
                "fat_g": total_fat,
                "fiber_g": total_fiber,
                "sugar_g": total_sugar,
                "sodium_mg": total_sodium,
            },
            "targets": {
                "calories_kcal": target_kcal,
                "protein_g": target_protein,
                "carbs_g": target_carbs,
                "fat_g": target_fat,
            },
            "remaining": {
                "calories_kcal": max(0, target_kcal - total_kcal),
                "protein_g": max(0.0, round(target_protein - total_protein, 1)),
                "carbs_g": max(0.0, round(target_carbs - total_carbs, 1)),
                "fat_g": max(0.0, round(target_fat - total_fat, 1)),
            },
        }, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Log Food to Diary",
        description="Logs food entry with quantity in grams, scoped to user and idempotent by client_uuid.",
        tags=["Nutrition & Food Logging"]
    )
    def post(self, request):
        user = request.user
        ingredient_id = request.data.get('ingredient_id')
        quantity_g = float(request.data.get('quantity_g', request.data.get('quantity', 100.0)))
        meal = request.data.get('meal', 'lunch').lower()
        client_uuid = request.data.get('client_uuid')
        logged_at_str = request.data.get('logged_at')

        try:
            ingredient = KineticIngredient.objects.get(pk=ingredient_id, verified=True)
        except KineticIngredient.DoesNotExist:
            return Response({"detail": "Ingredient not found in closed library."}, status=status.HTTP_404_NOT_FOUND)

        logged_at = timezone.now()
        if logged_at_str:
            parsed = parse_date(logged_at_str)
            if parsed:
                logged_at = timezone.datetime.combine(parsed, timezone.now().time()).replace(tzinfo=timezone.utc)

        defaults = {
            'user': user,
            'ingredient': ingredient,
            'quantity_g': quantity_g,
            'meal': meal,
            'logged_at': logged_at,
        }

        if client_uuid:
            entry, created = KineticDiaryEntry.objects.update_or_create(
                client_uuid=client_uuid,
                defaults=defaults,
            )
        else:
            entry = KineticDiaryEntry.objects.create(**defaults)

        calc = calculate_macros_pure(ingredient, quantity_g)
        return Response({
            "status": "success",
            "entry_id": entry.id,
            "client_uuid": str(entry.client_uuid),
            "ingredient": ingredient.name,
            "quantity_g": quantity_g,
            "meal": entry.meal,
            "calories_kcal": calc["calories_kcal"],
            "protein_g": calc["protein_g"],
            "carbs_g": calc["carbs_g"],
            "fat_g": calc["fat_g"],
        }, status=status.HTTP_201_CREATED)


class NutritionDiaryDetailAPIView(APIView):
    """
    Update or delete logged diary entries, strictly isolated to the owning user.
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, entry_id):
        user = request.user
        try:
            entry = KineticDiaryEntry.objects.get(pk=entry_id, user=user)
        except KineticDiaryEntry.DoesNotExist:
            return Response({"detail": "Diary entry not found."}, status=status.HTTP_404_NOT_FOUND)

        if 'quantity_g' in request.data:
            entry.quantity_g = float(request.data['quantity_g'])
        if 'meal' in request.data:
            entry.meal = request.data['meal'].lower()
        entry.save()

        calc = calculate_macros_pure(entry.ingredient, entry.quantity_g)
        return Response({
            "status": "success",
            "entry_id": entry.id,
            "quantity_g": entry.quantity_g,
            "calories_kcal": calc["calories_kcal"],
            "protein_g": calc["protein_g"],
        }, status=status.HTTP_200_OK)

    def delete(self, request, entry_id):
        user = request.user
        try:
            entry = KineticDiaryEntry.objects.get(pk=entry_id, user=user)
        except KineticDiaryEntry.DoesNotExist:
            return Response({"detail": "Diary entry not found."}, status=status.HTTP_404_NOT_FOUND)

        entry.delete()
        return Response({"status": "success", "message": "Diary entry removed."}, status=status.HTTP_200_OK)


# ─── ADMIN CLOSED INGREDIENT MANAGEMENT ────────────────────────────────────────

class AdminNutritionIngredientListCreateView(APIView):
    """
    Super Admin / Gym Owner ingredient management: add or list closed library items.
    Protected strictly by IsSuperAdmin with 2FA admin_jwt scope and audit logging.
    """
    permission_classes = [IsSuperAdmin]

    @extend_schema(
        summary="Admin Ingredient Management List",
        description="Returns all closed library ingredients for admin oversight.",
        tags=["Super Admin Gym Management"]
    )
    def get(self, request):
        ingredients = KineticIngredient.objects.all().order_by('category', 'name')
        results = [
            {
                "id": ing.id,
                "name": ing.name,
                "category": ing.category,
                "calories_kcal": ing.calories_kcal,
                "protein_g": ing.protein_g,
                "carbs_g": ing.carbs_g,
                "fat_g": ing.fat_g,
                "fiber_g": ing.fiber_g,
                "sugar_g": ing.sugar_g,
                "sodium_mg": ing.sodium_mg,
                "verified": ing.verified,
            }
            for ing in ingredients
        ]
        return Response({"count": len(results), "results": results}, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Admin Add Closed Ingredient",
        description="Creates a new reviewed food in the closed library.",
        tags=["Super Admin Gym Management"]
    )
    def post(self, request):
        admin_user = request.user
        name = request.data.get('name')
        category = request.data.get('category', 'General')
        calories_kcal = float(request.data.get('calories_kcal', 0.0))
        protein_g = float(request.data.get('protein_g', 0.0))
        carbs_g = float(request.data.get('carbs_g', 0.0))
        fat_g = float(request.data.get('fat_g', 0.0))
        fiber_g = float(request.data.get('fiber_g', 0.0))
        sugar_g = float(request.data.get('sugar_g', 0.0))
        sodium_mg = float(request.data.get('sodium_mg', 0.0))

        if not name:
            return Response({"detail": "Food name is required."}, status=status.HTTP_400_BAD_REQUEST)

        ingredient = KineticIngredient.objects.create(
            name=name,
            category=category,
            calories_kcal=calories_kcal,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            sugar_g=sugar_g,
            sodium_mg=sodium_mg,
            verified=True,
            created_by=admin_user,
        )

        AdminAuditLog.objects.create(
            admin_user=admin_user,
            action='create',
            target_model='KineticIngredient',
            target_id=str(ingredient.id),
            details=f"Created ingredient {ingredient.name} ({ingredient.calories_kcal} kcal/100g)",
            ip_address=get_client_ip(request),
        )

        return Response({
            "status": "success",
            "ingredient_id": ingredient.id,
            "name": ingredient.name,
        }, status=status.HTTP_201_CREATED)


class AdminNutritionIngredientDetailView(APIView):
    """
    Super Admin / Gym Owner ingredient edit or delete.
    """
    permission_classes = [IsSuperAdmin]

    def put(self, request, ingredient_id):
        admin_user = request.user
        try:
            ingredient = KineticIngredient.objects.get(pk=ingredient_id)
        except KineticIngredient.DoesNotExist:
            return Response({"detail": "Ingredient not found."}, status=status.HTTP_404_NOT_FOUND)

        old_data = {'name': ingredient.name, 'calories_kcal': ingredient.calories_kcal}
        for field in ['name', 'category', 'calories_kcal', 'protein_g', 'carbs_g', 'fat_g', 'fiber_g', 'sugar_g', 'sodium_mg']:
            if field in request.data:
                setattr(ingredient, field, request.data[field])
        ingredient.save()

        AdminAuditLog.objects.create(
            admin_user=admin_user,
            action='update',
            target_model='KineticIngredient',
            target_id=str(ingredient.id),
            details=f"Updated ingredient {ingredient.name}",
            ip_address=get_client_ip(request),
        )

        return Response({"status": "success", "ingredient_id": ingredient.id}, status=status.HTTP_200_OK)

    def delete(self, request, ingredient_id):
        admin_user = request.user
        try:
            ingredient = KineticIngredient.objects.get(pk=ingredient_id)
        except KineticIngredient.DoesNotExist:
            return Response({"detail": "Ingredient not found."}, status=status.HTTP_404_NOT_FOUND)

        name = ingredient.name
        ingredient.delete()

        AdminAuditLog.objects.create(
            admin_user=admin_user,
            action='delete',
            target_model='KineticIngredient',
            target_id=str(ingredient_id),
            details=f"Deleted ingredient {name}",
            ip_address=get_client_ip(request),
        )

        return Response({"status": "success", "message": f"Ingredient '{name}' deleted."}, status=status.HTTP_200_OK)
