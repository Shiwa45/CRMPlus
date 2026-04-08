from django.views.generic import ListView, TemplateView, DetailView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.db.models import Count
from .models import Hostel, Room, HostelAllocation, HostelAttendance


class HostelDashboardView(LoginRequiredMixin, TemplateView):
    template_name = "hostel/dashboard.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Hostel Management",
            "hostels": Hostel.objects.filter(is_active=True).annotate(
                allocated_rooms=Count("rooms__allocations", filter=__import__("django.db.models", fromlist=["Q"]).Q(rooms__allocations__status="active"))
            ),
            "total_students": HostelAllocation.objects.filter(status="active").count(),
            "total_rooms": Room.objects.filter(is_active=True).count(),
            "available_rooms": Room.objects.filter(is_active=True).extra(
                where=["current_occupancy < capacity"]
            ).count(),
        })
        return ctx


class RoomListView(LoginRequiredMixin, ListView):
    model = Room
    template_name = "hostel/rooms.html"
    context_object_name = "rooms"

    def get_queryset(self):
        qs = Room.objects.filter(is_active=True).select_related("hostel")
        hostel_id = self.request.GET.get("hostel_id")
        if hostel_id:
            qs = qs.filter(hostel_id=hostel_id)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Hostel Rooms",
            "hostels": Hostel.objects.filter(is_active=True),
        })
        return ctx


class AllocationView(LoginRequiredMixin, ListView):
    model = HostelAllocation
    template_name = "hostel/allocations.html"
    context_object_name = "allocations"
    paginate_by = 20

    def get_queryset(self):
        return HostelAllocation.objects.filter(
            status="active"
        ).select_related("student", "room__hostel").order_by("room__hostel", "room__room_number")

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Hostel Allocations",
            "hostels": Hostel.objects.filter(is_active=True),
        })
        return ctx
