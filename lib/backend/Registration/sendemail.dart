/*import 'package:aws_sesv2_api/sesv2-2019-09-27.dart';


Future<SendEmailResponse> sendEmail({
  required EmailContent content,
  String? configurationSetName,
  Destination? destination,
  List<MessageTag>? emailTags,
  String? feedbackForwardingEmailAddress,
  String? feedbackForwardingEmailAddressIdentityArn,
  String? fromEmailAddress,
  String? fromEmailAddressIdentityArn,
  ListManagementOptions? listManagementOptions,
  List<String>? replyToAddresses,
}) async {
  ArgumentError.checkNotNull(content, 'content');
  final $payload = <String, dynamic>{
    'Content': content,
    if (configurationSetName != null)
      'ConfigurationSetName': configurationSetName,
    if (destination != null) 'Destination': destination,
    if (emailTags != null) 'EmailTags': emailTags,
    if (feedbackForwardingEmailAddress != null)
      'FeedbackForwardingEmailAddress': feedbackForwardingEmailAddress,
    if (feedbackForwardingEmailAddressIdentityArn != null)
      'FeedbackForwardingEmailAddressIdentityArn':
          feedbackForwardingEmailAddressIdentityArn,
    if (fromEmailAddress != null) 'FromEmailAddress': fromEmailAddress,
    if (fromEmailAddressIdentityArn != null)
      'FromEmailAddressIdentityArn': fromEmailAddressIdentityArn,
    if (listManagementOptions != null)
      'ListManagementOptions': listManagementOptions,
    if (replyToAddresses != null) 'ReplyToAddresses': replyToAddresses,
  };
  final response = await _protocol.send(
    payload: $payload,
    method: 'POST',
    requestUri: '/v2/email/outbound-emails',
    exceptionFnMap: _exceptionFns,
  );
  return SendEmailResponse.fromJson(response);
}


Future<void> sendEmailPlease( {required EmailContent content, required destination, required fromEmailAddressIdentityArn}) async {


}*/