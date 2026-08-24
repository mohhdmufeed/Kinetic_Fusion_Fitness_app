# -*- coding: utf-8 -*-
"""
Kinetic Precision - Centralized Canonical Unit Conversion Engine
All internal storage across database models, ML features, and API payloads is strictly Kilograms (kg).
Conversions are purely presentational with deterministic rounding to eliminate numerical drift.
"""

KG_TO_LB_FACTOR = 2.20462262185


def kg_to_lb(kg: float, precision: int = 1) -> float:
    """Converts canonical kilograms to pounds for display."""
    if kg is None:
        return 0.0
    return round(float(kg) * KG_TO_LB_FACTOR, precision)


def lb_to_kg(lb: float, precision: int = 2) -> float:
    """Converts display pounds to canonical kilograms for storage."""
    if lb is None:
        return 0.0
    return round(float(lb) / KG_TO_LB_FACTOR, precision)


def to_display_weight(kg: float, use_kilograms: bool = True, precision: int = 1) -> tuple[float, str]:
    """
    Returns (display_value, unit_string) given canonical kilograms.
    Example: to_display_weight(84.0, use_kilograms=False) -> (185.2, "lb")
    """
    if kg is None:
        return (0.0, "kg" if use_kilograms else "lb")

    if use_kilograms:
        return (round(float(kg), precision), "kg")
    return (kg_to_lb(kg, precision=precision), "lb")


def from_display_weight(display_val: float, use_kilograms: bool = True, precision: int = 2) -> float:
    """
    Converts user-entered display weight to canonical kilograms for storage.
    """
    if display_val is None:
        return 0.0

    if use_kilograms:
        return round(float(display_val), precision)
    return lb_to_kg(display_val, precision=precision)
