from django.views.generic import ListView, TemplateView, CreateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse_lazy
from .models import Vehicle, Route, RouteStop, StudentTransport


class TransportDashboardView(LoginRequiredMixin, TemplateView):
    template_name = "transport/dashboard.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Transport Management",
            "total_vehicles": Vehicle.objects.filter(is_active=True).count(),
            "total_routes": Route.objects.filter(is_active=True).count(),
            "students_using_transport": StudentTransport.objects.filter(is_active=True).count(),
            "routes": Route.objects.filter(is_active=True).prefetch_related("stops", "students"),
            "vehicles": Vehicle.objects.filter(is_active=True).select_related("driver"),
        })
        return ctx


class RouteListView(LoginRequiredMixin, ListView):
    model = Route
    template_name = "transport/routes.html"
    context_object_name = "routes"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Transport Routes",
            "vehicles": Vehicle.objects.filter(is_active=True),
        })
        return ctx


class VehicleListView(LoginRequiredMixin, ListView):
    model = Vehicle
    template_name = "transport/vehicles.html"
    context_object_name = "vehicles"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        from django.utils import timezone
        today = timezone.now().date()
        ctx.update({
            "page_title": "Vehicles",
            "expiring_soon": Vehicle.objects.filter(
                is_active=True, insurance_expiry__lte=today
            ),
        })
        return ctx


class StudentTransportView(LoginRequiredMixin, ListView):
    model = StudentTransport
    template_name = "transport/student_allocation.html"
    context_object_name = "allocations"
    paginate_by = 25

    def get_queryset(self):
        return StudentTransport.objects.filter(
            is_active=True
        ).select_related("student", "route", "stop").order_by("route", "stop__stop_order")

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Student Transport Allocation",
            "routes": Route.objects.filter(is_active=True),
        })
        return ctx
