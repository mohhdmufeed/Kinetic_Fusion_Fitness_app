# -*- coding: utf-8 -*-
import uuid
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class KineticIngredient(models.Model):
    """
    High-performance canonical food and ingredient table.
    All nutritional values are strictly stored per 100g / 100ml.
    """
    SOURCE_CHOICES = (
        ('local_curated', 'Local Curated Starter Dataset'),
        ('open_food_facts', 'Open Food Facts Live Cache'),
        ('user_submitted', 'User Submitted Entry'),
    )

    name = models.CharField(max_length=255, db_index=True)
    category = models.CharField(max_length=64, default='General', db_index=True)
    brand = models.CharField(max_length=128, null=True, blank=True)
    barcode = models.CharField(max_length=64, null=True, blank=True, db_index=True)

    # Macros strictly stored per 100g / 100ml canonical base
    calories_kcal = models.FloatField(help_text="Calories in kcal per 100g")
    protein_g = models.FloatField(help_text="Protein in grams per 100g")
    carbs_g = models.FloatField(help_text="Carbohydrates in grams per 100g")
    fat_g = models.FloatField(help_text="Fat in grams per 100g")
    fiber_g = models.FloatField(default=0.0, help_text="Dietary fiber in grams per 100g")
    sugar_g = models.FloatField(default=0.0, help_text="Sugars in grams per 100g")
    sodium_mg = models.FloatField(default=0.0, help_text="Sodium in milligrams per 100g")

    # Data governance
    source = models.CharField(max_length=32, choices=SOURCE_CHOICES, default='local_curated', db_index=True)
    verified = models.BooleanField(default=True, help_text="True if approved for global athlete search")
    household_units = models.JSONField(
        default=dict,
        blank=True,
        help_text="Custom per-ingredient household unit mappings to grams (e.g. {'cup': 195.0, 'piece': 120.0})"
    )

    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='submitted_ingredients',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        verbose_name = 'Kinetic Ingredient'
        verbose_name_plural = 'Kinetic Ingredients'

    def __str__(self):
        brand_str = f" ({self.brand})" if self.brand else ""
        return f"{self.name}{brand_str} - {self.calories_kcal:.0f} kcal / 100g"


class KineticDiaryEntry(models.Model):
    """
    Athlete meal log entry, scoped to request.user and supporting offline UUID synchronization.
    """
    MEAL_CHOICES = (
        ('breakfast', 'Breakfast'),
        ('lunch', 'Lunch'),
        ('dinner', 'Dinner'),
        ('snack', 'Snack'),
    )

    client_uuid = models.UUIDField(default=uuid.uuid4, unique=True, db_index=True)
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='kinetic_diary_entries',
    )
    ingredient = models.ForeignKey(
        KineticIngredient,
        on_delete=models.CASCADE,
        related_name='diary_logs',
    )
    quantity_g = models.FloatField(help_text="Canonical gram weight consumed")
    unit_entered = models.CharField(max_length=32, default='g')
    unit_quantity = models.FloatField(default=100.0)
    meal = models.CharField(max_length=16, choices=MEAL_CHOICES, default='lunch', db_index=True)
    logged_at = models.DateTimeField(default=timezone.now, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-logged_at']
        verbose_name = 'Kinetic Diary Entry'
        verbose_name_plural = 'Kinetic Diary Entries'

    def __str__(self):
        return f"{self.user.username} - {self.meal}: {self.ingredient.name} ({self.quantity_g}g)"

    @property
    def calories_kcal(self) -> float:
        return round((self.ingredient.calories_kcal / 100.0) * self.quantity_g, 1)

    @property
    def protein_g(self) -> float:
        return round((self.ingredient.protein_g / 100.0) * self.quantity_g, 1)

    @property
    def carbs_g(self) -> float:
        return round((self.ingredient.carbs_g / 100.0) * self.quantity_g, 1)

    @property
    def fat_g(self) -> float:
        return round((self.ingredient.fat_g / 100.0) * self.quantity_g, 1)

    @property
    def fiber_g(self) -> float:
        return round((self.ingredient.fiber_g / 100.0) * self.quantity_g, 1)

    @property
    def sugar_g(self) -> float:
        return round((self.ingredient.sugar_g / 100.0) * self.quantity_g, 1)

    @property
    def sodium_mg(self) -> float:
        return round((self.ingredient.sodium_mg / 100.0) * self.quantity_g, 1)
