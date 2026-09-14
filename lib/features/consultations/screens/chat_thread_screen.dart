import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled3/core/constants/setting.dart';
import '../../../core/theme/app_colors.dart';
import '../data/consultation_message_model.dart';
import '../view_models/chat_thread_cubit.dart';
import '../view_models/chat_thread_state.dart';

/// One consultation's message thread (per appointment). Polls
/// GET .../messages every ~8s while visible and marks incoming messages as
/// read on load/poll - see [ChatThreadCubit].
class ChatThreadScreen extends StatefulWidget {
  final int appointmentId;
  final String otherPartyName;
  final int currentUserId;

  const ChatThreadScreen({
    super.key,
    required this.appointmentId,
    required this.otherPartyName,
    required this.currentUserId,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  late final ChatThreadCubit _cubit;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = ChatThreadCubit(appointmentId: widget.appointmentId)
      ..load()
      ..startPolling();
  }

  @override
  void dispose() {
    _cubit.close();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend() async {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    await _cubit.send(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final isEn = settingsState.locale.languageCode == 'en';
    final isDark = settingsState.themeMode == ThemeMode.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.textDark;
    final primaryGreen = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.backgroundBeige;
    final appBarBg = isDark ? AppColors.darkCard : AppColors.white;
    final inputBg = isDark ? AppColors.darkCard : AppColors.white;

    return BlocProvider.value(
      value: _cubit,
      child: Directionality(
        textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
        child: Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: appBarBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(isEn ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, color: primaryGreen),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: primaryGreen.withOpacity(0.15),
                  child: Icon(Icons.person_rounded, color: primaryGreen, size: 18.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    widget.otherPartyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: textColor),
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: BlocConsumer<ChatThreadCubit, ChatThreadState>(
                    listener: (context, state) {
                      if (state.status == ChatThreadStatus.loaded) _scrollToBottom();
                    },
                    builder: (context, state) {
                      if (state.status == ChatThreadStatus.loading || state.status == ChatThreadStatus.initial) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state.status == ChatThreadStatus.failure && state.messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.wifi_off_rounded, size: 40.sp, color: AppColors.textLightGrey),
                                SizedBox(height: 12.h),
                                Text(
                                  isEn ? 'Failed to load messages' : 'تعذّر تحميل الرسائل',
                                  style: TextStyle(color: textColor, fontSize: 14.sp, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 10.h),
                                TextButton(
                                  onPressed: () => context.read<ChatThreadCubit>().load(),
                                  child: Text(isEn ? 'Retry' : 'إعادة المحاولة', style: TextStyle(color: primaryGreen)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state.messages.isEmpty) {
                        return Center(
                          child: Text(
                            isEn ? 'Say hello!' : 'ابدأ المحادثة!',
                            style: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          return _MessageBubble(
                            message: message,
                            isMine: message.isMine(widget.currentUserId),
                            isDark: isDark,
                            primaryGreen: primaryGreen,
                            textColor: textColor,
                          );
                        },
                      );
                    },
                  ),
                ),
                _ChatInputBar(
                  controller: _inputController,
                  inputBg: inputBg,
                  textColor: textColor,
                  primaryGreen: primaryGreen,
                  isEn: isEn,
                  onSend: _handleSend,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ConsultationMessageModel message;
  final bool isMine;
  final bool isDark;
  final Color primaryGreen;
  final Color textColor;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isDark,
    required this.primaryGreen,
    required this.textColor,
  });

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final mm = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hh:$mm $period';
  }

  @override
  Widget build(BuildContext context) {
    final isSystem = message.senderRole == 'system';
    if (isSystem) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.textLightGrey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              message.content,
              style: TextStyle(fontSize: 11.5.sp, color: AppColors.textLightGrey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final bubbleBg = isMine ? primaryGreen : (isDark ? AppColors.darkCard : AppColors.white);
    final bubbleTextColor = isMine ? Colors.white : textColor;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14.r),
            topRight: Radius.circular(14.r),
            bottomLeft: Radius.circular(isMine ? 14.r : 2.r),
            bottomRight: Radius.circular(isMine ? 2.r : 14.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.content, style: TextStyle(fontSize: 13.5.sp, color: bubbleTextColor, height: 1.35)),
            SizedBox(height: 4.h),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10.sp,
                color: isMine ? Colors.white.withOpacity(0.75) : AppColors.textLightGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Color inputBg;
  final Color textColor;
  final Color primaryGreen;
  final bool isEn;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.inputBg,
    required this.textColor,
    required this.primaryGreen,
    required this.isEn,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatThreadCubit, ChatThreadState>(
      buildWhen: (previous, current) => previous.isSending != current.isSending,
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
          decoration: BoxDecoration(
            color: inputBg,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: TextStyle(fontSize: 13.5.sp, color: textColor),
                    decoration: InputDecoration(
                      hintText: isEn ? 'Type a message…' : 'اكتب رسالة…',
                      hintStyle: TextStyle(color: AppColors.textLightGrey, fontSize: 13.sp),
                      filled: true,
                      fillColor: AppColors.textLightGrey.withOpacity(0.1),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                InkWell(
                  onTap: state.isSending ? null : onSend,
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                    child: state.isSending
                        ? Padding(
                            padding: EdgeInsets.all(11.w),
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
