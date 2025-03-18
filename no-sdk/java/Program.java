package sigv4.signing;

import sigv4.signing.samples.ApiGatewaySample;
import sigv4.signing.samples.BedrockConverseSample;
import sigv4.signing.samples.SESSample;

public class Program {
    public static void main(String[] args) {
        // 获取AWS默认区域，如果未设置则使用ap-northeast-1作为默认值
        String region = System.getenv("AWS_DEFAULT_REGION") != null
            ? System.getenv("AWS_DEFAULT_REGION") 
            : "ap-northeast-1";

        // 调用SESSample的run方法发送邮件
        SESSample.run(region, "from_email_address@yourdomain.com", "rcpt@example.com", "The subject", "The body");
    }
}
