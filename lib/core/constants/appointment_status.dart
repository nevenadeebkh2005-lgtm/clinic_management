/// ⚠️ 19/8: حالة الموعد الحقيقية متل ما بيرجعها الباك (Postman:
/// Appointment/Patient + Appointment/Doctor) - 5 حالات، مو 3 متل
/// النسخة القديمة الوهمية (upcoming/completed/cancelled).
enum AppointmentApiStatus { scheduled,checkedIn, inProgress, completed, cancelled, noShow }

AppointmentApiStatus appointmentApiStatusFromString(String raw) {
  switch (raw) {
    case 'in_progress':
      return AppointmentApiStatus.inProgress;
  case 'checked_in':
  return AppointmentApiStatus.checkedIn;
    case 'completed':
      return AppointmentApiStatus.completed;
    case 'cancelled':
      return AppointmentApiStatus.cancelled;
    case 'no_show':
      return AppointmentApiStatus.noShow;
    default:
      return AppointmentApiStatus.scheduled;
  }
}

extension AppointmentApiStatusX on AppointmentApiStatus {
  String get asString {
    switch (this) {
      case AppointmentApiStatus.inProgress:
        return 'in_progress';
      case AppointmentApiStatus.completed:
        return 'completed';
     case AppointmentApiStatus.checkedIn:
    return 'checked_in';
    case AppointmentApiStatus.cancelled:
        return 'cancelled';
      case AppointmentApiStatus.noShow:
        return 'no_show';
      case AppointmentApiStatus.scheduled:
        return 'scheduled';
    }
  }
}

/// تجميع الحالات الخمس لتبويبات الواجهة (قادمة/سابقة/ملغاة) - نفس
/// التصنيف المطلوب من المريض والطبيب:
/// - upcoming: لسا رح يصير (scheduled) أو عم يصير هلق (in_progress).
/// - history: خلص وقته (completed = حضر، no_show = ما حضر).
/// - cancelled: ملغى (من المريض أو الطبيب).
enum AppointmentTabGroup { upcoming, history, cancelled }

extension AppointmentApiStatusTabX on AppointmentApiStatus {
  AppointmentTabGroup get tabGroup {
    switch (this) {
      case AppointmentApiStatus.scheduled:
      case AppointmentApiStatus.checkedIn:
        return AppointmentTabGroup.upcoming;
      case AppointmentApiStatus.inProgress:
        return AppointmentTabGroup.upcoming;
      case AppointmentApiStatus.completed:
      case AppointmentApiStatus.noShow:
        return AppointmentTabGroup.history;
      case AppointmentApiStatus.cancelled:
        return AppointmentTabGroup.cancelled;
    }
  }
}
