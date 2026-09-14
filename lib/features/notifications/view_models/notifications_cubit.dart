import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/notifications_repository.dart';
import 'notifications_state.dart';

/// بتحمّل إشعارات المستخدم الحالي (GET /notifications) وبتعمل poll كل
/// ~30 ثانية طول ما هي provided - مناسبة تنعمل provide مرة وحدة بأعلى
/// شجرة الشاشة الرئيسية (متل PatientAppointmentsCubit/ConsultationsInboxCubit)
/// حتى شارة العدد الغير مقروء عالجرس تضل حيّة بغض النظر عن التاب المفتوح.
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;
  Timer? _pollTimer;

  NotificationsCubit({NotificationsRepository? repository})
      : _repository = repository ?? NotificationsRepository(),
        super(const NotificationsState());

  Future<void> load() async {
    if (state.items.isEmpty) {
      emit(state.copyWith(status: NotificationsStatus.loading));
    }
    try {
      final items = await _repository.getNotifications();
      if (isClosed) return;
      emit(state.copyWith(status: NotificationsStatus.loaded, items: items, errorMessage: null));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: NotificationsStatus.failure, errorMessage: e.toString()));
    }
  }

  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => load());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// تحديث فوري (optimistic) لحالة القراءة محلياً + نداء الباك بالخلفية -
  /// هيك الشارة والقائمة بيتحدثوا لحظياً بدون ما ننتظر رد الشبكة.
  Future<void> markAsRead(int id) async {
    final current = state.items;
    final target = current.where((n) => n.id == id).firstOrNull;
    if (target == null || target.isRead) return;

    final updated = current.map((n) => n.id == id ? n.copyWith(isRead: true, readAt: DateTime.now()) : n).toList();
    emit(state.copyWith(items: updated));

    try {
      await _repository.markAsRead(id);
    } catch (_) {
      // فشل التحديث بالباك بهدوء - القراءة المحلية بتضل زي ما هي، وبتنعاد
      // مزامنتها صح بأول load() تالية (poll أو فتح الشاشة من جديد).
    }
  }

  Future<void> markAllAsRead() async {
    final updated = state.items.map((n) => n.copyWith(isRead: true, readAt: DateTime.now())).toList();
    emit(state.copyWith(items: updated));
    try {
      await _repository.markAllAsRead();
    } catch (_) {
      // نفس ملاحظة markAsRead - بيتصحح تلقائياً بأول تحديث تالي.
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
