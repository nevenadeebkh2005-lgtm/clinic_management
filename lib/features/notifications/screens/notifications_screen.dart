import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/theme/app_colors.dart';
import '../../consultations/screens/chat_thread_screen.dart';
import '../models/notification_model.dart';
import '../view_models/notifications_cubit.dart';
import '../view_models/notifications_state.dart';

/// شاشة الإشعارات الحقيقية (GET /notifications) - مشتركة بين الطبيب
/// والمريض. لازم تنفتح فوق [NotificationsCubit] موفّرة مسبقاً (عبر
/// BlocProvider.value) حتى شارة العدد على الجرس وقائمة الإشعارات
/// يستخدموا نفس الـ instance (ونفس الـ polling).
class NotificationsScreen extends StatefulWidget {
  final int currentUserId;

  /// بيتنفّذ لما المستخدم يضغط إشعار من نوع appointment_* (تأكيد/إلغاء/
  /// تذكير/موعد مكتمل) - كل جهة (طبيب/مريض) عندها شاشة مواعيد مختلفة
  /// تماماً، فمنسيب القرار لصاحب الشاشة بدل ما نفترض واحدة هون.
  final void Function(BuildContext context, NotificationModel notification)? onOpenAppointment;

  const NotificationsScreen({super.key, required this.currentUserId, this.onOpenAppointment});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().load();
  }

  Future<void> _handleTap(NotificationModel notification) async {
    final cubit = context.read<NotificationsCubit>();
    cubit.markAsRead(notification.id);

    if (notification.type == NotificationTypes.consultationMessageReceived) {
      final appointmentId = notification.appointmentId;
      if (appointmentId == null) return;
      final settingsState = context.read<SettingsCubit>().state;
      final isEn = settingsState.locale.languageCode == 'en';
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            appointmentId: appointmentId,
            otherPartyName: notification.data['sender_name']?.toString() ?? (isEn ? 'Consultation' : 'استشارة'),
            currentUserId: widget.currentUserId,
          ),
        ),
      );
      return;
    }

    if (NotificationTypes.isAppointment(notification.type)) {
      widget.onOpenAppointment?.call(context, notification);
    }
  }

  IconData _iconFor(String type) {
    if (type == NotificationTypes.consultationMessageReceived) return Icons.chat_bubble_outline_rounded;
    if (NotificationTypes.isConsultation(type)) return Icons.medical_services_outlined;
    if (NotificationTypes.isAppointment(type)) return Icons.event_note_rounded;
    if (type == NotificationTypes.paymentConfirmed || type == NotificationTypes.paymentFailed || type == NotificationTypes.invoiceIssued) {
      return Icons.receipt_long_rounded;
    }
    if (type == NotificationTypes.doctorVerified || type == NotificationTypes.doctorRejected) return Icons.verified_outlined;
    return Icons.notifications_none_rounded;
  }

  String _formatTime(DateTime dt, bool isEn) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final hh = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final mm = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return '$hh:$mm $period';
    }
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isEn = settingsState.locale.languageCode == 'en';
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.backgroundBeige;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;

    return Directionality(
      textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(isEn ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, color: primaryGreen),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            isEn ? 'Notifications' : 'الإشعارات',
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: primaryGreen),
          ),
          actions: [
            BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, state) {
                if (state.unreadCount == 0) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => context.read<NotificationsCubit>().markAllAsRead(),
                  child: Text(
                    isEn ? 'Mark all read' : 'وضع الكل كمقروء',
                    style: TextStyle(color: primaryGreen, fontSize: 12.5.sp, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
            SizedBox(width: 8.w),
          ],
        ),
        body: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            final cubit = context.read<NotificationsCubit>();

            if (state.status == NotificationsStatus.loading || state.status == NotificationsStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == NotificationsStatus.failure && state.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 40.sp, color: AppColors.textLightGrey),
                      SizedBox(height: 12.h),
                      Text(
                        isEn ? 'Failed to load notifications' : 'تعذّر تحميل الإشعارات',
                        style: TextStyle(color: textColor, fontSize: 14.sp, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 10.h),
                      TextButton(
                        onPressed: () => cubit.load(),
                        child: Text(isEn ? 'Retry' : 'إعادة المحاولة', style: TextStyle(color: primaryGreen)),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72.w,
                        height: 72.h,
                        decoration: BoxDecoration(color: primaryGreen.withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(Icons.notifications_none_rounded, size: 32.sp, color: primaryGreen),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        isEn ? 'No notifications yet' : 'لا توجد إشعارات بعد',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        isEn ? "You'll see updates about your appointments and messages here." : 'ستظهر هنا تحديثات مواعيدك ورسائلك.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5.sp, color: AppColors.textLightGrey),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => cubit.load(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final n = state.items[index];
                  return InkWell(
                    onTap: () => _handleTap(n),
                    borderRadius: BorderRadius.circular(14.r),
                    child: Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14.r),
                        border: !n.isRead ? Border.all(color: primaryGreen.withOpacity(0.4)) : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(color: primaryGreen.withOpacity(0.12), shape: BoxShape.circle),
                            child: Icon(_iconFor(n.type), color: primaryGreen, size: 20.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: textColor),
                                      ),
                                    ),
                                    Text(_formatTime(n.createdAt, isEn), style: TextStyle(fontSize: 11.sp, color: AppColors.textLightGrey)),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  n.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    color: !n.isRead ? textColor : AppColors.textLightGrey,
                                    fontWeight: !n.isRead ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!n.isRead) ...[
                            SizedBox(width: 8.w),
                            Container(
                              margin: EdgeInsets.only(top: 4.h),
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
