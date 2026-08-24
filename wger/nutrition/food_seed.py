# -*- coding: utf-8 -*-
"""
Kinetic Precision - Curated Whole Foods Starter Dataset
Canonical 100g/ml reference nutrients with precise household unit weights.
"""
from wger.nutrition.models.kinetic_nutrition import KineticIngredient


CURATED_FOODS = [
    {
        "name": "Chicken breast, skinless, cooked",
        "category": "Meat & Poultry",
        "brand": "Generic Whole Food",
        "calories_kcal": 165.0,
        "protein_g": 31.0,
        "carbs_g": 0.0,
        "fat_g": 3.6,
        "fiber_g": 0.0,
        "sugar_g": 0.0,
        "sodium_mg": 74.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "piece": 120.0,
            "breast": 172.0,
            "cup": 140.0,
            "oz": 28.35,
        }
    },
    {
        "name": "Chicken thigh, skinless, cooked",
        "category": "Meat & Poultry",
        "brand": "Generic Whole Food",
        "calories_kcal": 209.0,
        "protein_g": 26.0,
        "carbs_g": 0.0,
        "fat_g": 10.9,
        "fiber_g": 0.0,
        "sugar_g": 0.0,
        "sodium_mg": 86.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "piece": 95.0,
            "thigh": 95.0,
            "cup": 140.0,
            "oz": 28.35,
        }
    },
    {
        "name": "Atlantic Salmon, cooked",
        "category": "Fish & Seafood",
        "brand": "Generic Whole Food",
        "calories_kcal": 206.0,
        "protein_g": 22.1,
        "carbs_g": 0.0,
        "fat_g": 12.3,
        "fiber_g": 0.0,
        "sugar_g": 0.0,
        "sodium_mg": 59.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "fillet": 150.0,
            "portion": 150.0,
            "oz": 28.35,
        }
    },
    {
        "name": "Whole Large Egg, boiled",
        "category": "Eggs & Dairy",
        "brand": "Generic Whole Food",
        "calories_kcal": 143.0,
        "protein_g": 12.6,
        "carbs_g": 0.7,
        "fat_g": 9.5,
        "fiber_g": 0.0,
        "sugar_g": 0.4,
        "sodium_mg": 124.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "piece": 50.0,
            "egg": 50.0,
            "large": 50.0,
        }
    },
    {
        "name": "Greek Yogurt, plain nonfat",
        "category": "Eggs & Dairy",
        "brand": "Generic Whole Food",
        "calories_kcal": 59.0,
        "protein_g": 10.0,
        "carbs_g": 3.6,
        "fat_g": 0.4,
        "fiber_g": 0.0,
        "sugar_g": 3.2,
        "sodium_mg": 36.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "cup": 245.0,
            "container": 150.0,
            "tbsp": 15.0,
        }
    },
    {
        "name": "Brown Rice, cooked",
        "category": "Grains & Pasta",
        "brand": "Generic Whole Food",
        "calories_kcal": 123.0,
        "protein_g": 2.7,
        "carbs_g": 25.6,
        "fat_g": 1.0,
        "fiber_g": 1.6,
        "sugar_g": 0.2,
        "sodium_mg": 2.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "cup": 195.0,
            "bowl": 250.0,
        }
    },
    {
        "name": "White Jasmine Rice, cooked",
        "category": "Grains & Pasta",
        "brand": "Generic Whole Food",
        "calories_kcal": 130.0,
        "protein_g": 2.7,
        "carbs_g": 28.2,
        "fat_g": 0.3,
        "fiber_g": 0.4,
        "sugar_g": 0.1,
        "sodium_mg": 1.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "cup": 186.0,
            "bowl": 250.0,
        }
    },
    {
        "name": "Rolled Oats, dry",
        "category": "Grains & Pasta",
        "brand": "Generic Whole Food",
        "calories_kcal": 379.0,
        "protein_g": 13.2,
        "carbs_g": 67.7,
        "fat_g": 6.5,
        "fiber_g": 10.1,
        "sugar_g": 1.0,
        "sodium_mg": 6.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "cup": 80.0,
            "scoop": 40.0,
            "tbsp": 10.0,
        }
    },
    {
        "name": "Banana, fresh",
        "category": "Produce & Fruit",
        "brand": "Generic Whole Food",
        "calories_kcal": 89.0,
        "protein_g": 1.1,
        "carbs_g": 22.8,
        "fat_g": 0.3,
        "fiber_g": 2.6,
        "sugar_g": 12.2,
        "sodium_mg": 1.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "piece": 118.0,
            "medium": 118.0,
            "banana": 118.0,
        }
    },
    {
        "name": "Whey Protein Isolate (Vanilla)",
        "category": "Supplements",
        "brand": "Precision Nutrition",
        "calories_kcal": 370.0,
        "protein_g": 86.7,
        "carbs_g": 3.3,
        "fat_g": 1.0,
        "fiber_g": 0.5,
        "sugar_g": 1.0,
        "sodium_mg": 180.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "scoop": 30.0,
            "serving": 30.0,
        }
    },
    {
        "name": "Extra Virgin Olive Oil",
        "category": "Oils & Fats",
        "brand": "Generic Whole Food",
        "calories_kcal": 884.0,
        "protein_g": 0.0,
        "carbs_g": 0.0,
        "fat_g": 100.0,
        "fiber_g": 0.0,
        "sugar_g": 0.0,
        "sodium_mg": 2.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "tbsp": 14.0,
            "tsp": 4.5,
        }
    },
    {
        "name": "Broccoli, steamed",
        "category": "Produce & Fruit",
        "brand": "Generic Whole Food",
        "calories_kcal": 35.0,
        "protein_g": 2.4,
        "carbs_g": 7.2,
        "fat_g": 0.4,
        "fiber_g": 3.3,
        "sugar_g": 1.4,
        "sodium_mg": 41.0,
        "source": "local_curated",
        "verified": True,
        "household_units": {
            "cup": 91.0,
            "spear": 31.0,
        }
    }
]


def ensure_starter_foods_seeded():
    """Seeds starter curated whole foods into KineticIngredient if table is empty."""
    for item in CURATED_FOODS:
        KineticIngredient.objects.get_or_create(
            name=item["name"],
            defaults=item,
        )
