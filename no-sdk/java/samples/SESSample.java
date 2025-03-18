package sigv4.signing.samples;

import sigv4.signing.HttpHelpers;

public class SESSample {
    // 定义AWS SES服务名称
    private static final String SERVICE = "ses";

    // 发送邮件的入口方法
    public static void run(String region, String from, String to, String subject, String body) {
        try {
            // 构建请求URL，根据区域动态生成
            String requestUrl = String.format("https://email.%s.amazonaws.com/v2/email/outbound-emails", region);
            // 构建请求体JSON，包含邮件内容、收件人、发件人等信息， 详细消息格式参考 https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_SendEmail.html
            String payload = String.format("{\"Content\":{\"Simple\":{\"Body\":{\"Html\":{\"Charset\":\"utf8\",\"Data\":\"%s\"},\"Text\":{\"Charset\":\"utf8\",\"Data\":\"%s\"}},\"Subject\":{\"Charset\":\"utf8\",\"Data\":\"%s\"}}},\"Destination\":{\"ToAddresses\":[\"%s\"]},\"FromEmailAddress\":\"%s\"}", body, body, subject, to, from);
            // 发送HTTP POST请求并获取响应
            String responseBody = HttpHelpers.post(SERVICE, region, requestUrl, payload);
            // 打印响应结果
            System.out.println(responseBody);
        } catch (Exception e) {
            // 捕获并处理异常
            System.err.println("Error in BedrockConverseSample: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
