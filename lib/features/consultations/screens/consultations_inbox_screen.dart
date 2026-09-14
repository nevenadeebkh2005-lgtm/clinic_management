import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/theme/app_colors.dart';
import '../data/consultation_model.dart';
import '../view_models/consultations_inbox_cubit.dart';
import '../view_models/consultations_inbox_state.dart';
import 'chat_thread_screen.dart';

/// Messages inbox - list of consultation threads (one per appointment),
/// tap to open the chat thread. Used embedded (as the "Messages" tab body,
/// no own AppBar) by both the doctor and patient main layout screens - see
/// [WeeklyTemplateEditorScreen] for the same `embedded` convention.
class ConsultationsInboxScreen extends StatefulWidget {
  final int currentUserId;
  final bool embedded;

  const ConsultationsInboxScreen({super.key, required this.currentUserId, this.embedded = false});

  @override
  State<ConsultationsInboxScreen> createState() => _ConsultationsInboxScreenState();
}

class _ConsultationsInboxScreenState extends State<ConsultationsInboxScreen> {
  late final ConsultationsInboxCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ConsultationsInboxCubit()
      ..load()
      ..startPolling();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: _ConsultationsInboxView(currentUserId: widget.currentUserId, embedded: widget.embedded),
    );
  }
}

class _ConsultationsInboxView extends StatelessWidget {
  final int currentUserId;
  final bool embedded;

  const _ConsultationsInboxView({required this.currentUserId, required this.embedded});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isEn = settingsState.locale.languageCode == 'en';
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.backgroundBeige;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;

    final body = BlocBuilder<ConsultationsInboxCubit, ConsultationsInboxState>(
      builder: (context, state) {
        final cubit = context.read<ConsultationsInboxCubit>();

        if (state.status == ConsultationsInboxStatus.loading || state.status == ConsultationsInboxStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ConsultationsInboxStatus.failure && state.items.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 40.sp, color: AppColors.textLightGrey),
                  SizedBox(height: 12.h),
                  Text(
                    isEn ? 'Failed to load conversations' : 'تعذّر تحميل المحادثات',
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
                    child: Icon(Icons.chat_bubble_outline_rounded, size: 32.sp, color: primaryGreen),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    isEn ? 'No conversations yet' : 'لا توجد محادثات بعد',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    isEn ? 'Your consultation messages will appear here.' : 'ستظهر رسائل استشاراتك هنا.',
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
              final item = state.items[index];
              return _ConsultationTile(
                consultation: item,
                isDark: isDark,
                isEn: isEn,
                textColor: textColor,
                primaryGreen: primaryGreen,
                cardBg: cardBg,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatThreadScreen(
                        appointmentId: item.appointmentId,
                        otherPartyName:
                            item.otherParty?.name ?? (isEn ? 'Consultation' : 'استشارة'),
                        currentUserId: currentUserId,
                      ),
                    ),
                  );
                  if (context.mounted) cubit.load();
                },
              );
            },
          ),
        );
      },
    );

    if (embedded) return body;

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
            isEn ? 'Messages' : 'الرسائل',
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: primaryGreen),
          ),
        ),
        body: body,
      ),
    );
  }
}

class _ConsultationTile extends StatelessWidget {
  final ConsultationModel consultation;
  final bool isDark;
  final bool isEn;
  final Color textColor;
  final Color primaryGreen;
  final Color cardBg;
  final VoidCallback onTap;

  const _ConsultationTile({
    required this.consultation,
    required this.isDark,
    required this.isEn,
    required this.textColor,
    required this.primaryGreen,
    required this.cardBg,
    required this.onTap,
  });

  String _formatTime(DateTime dt) {
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
    final hasUnread = consultation.unreadCount > 0;
    final name = consultation.otherParty?.name ?? (isEn ? 'Consultation' : 'استشارة');
    final preview = consultation.lastMessage?.content ?? (isEn ? 'No messages yet' : 'لا توجد رسائل بعد');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14.r),
          border: hasUnread ? Border.all(color: primaryGreen.withOpacity(0.4)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22.r,
              backgroundColor: primaryGreen.withOpacity(0.15),
              child: Icon(Icons.person_rounded, color: primaryGreen, size: 22.sp),
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
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: textColor),
                        ),
                      ),
                      if (consultation.lastMessage != null)
                        Text(
                          _formatTime(consultation.lastMessage!.createdAt),
                          style: TextStyle(fontSize: 11.sp, color: AppColors.textLightGrey),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            color: hasUnread ? textColor : AppColors.textLightGrey,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                          decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(20.r)),
                          child: Text(
                            consultation.unreadCount > 99 ? '99+' : '${consultation.unreadCount}',
                            style: TextStyle(fontSize: 10.5.sp, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
