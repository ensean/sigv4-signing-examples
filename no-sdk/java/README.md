# Java AWS SigV4 签名示例

本项目展示了如何在 Java 中不使用 AWS SDK 的情况下实现 AWS SigV4 签名，并调用 AWS 服务。

## 示例代码

当前项目包含以下示例：
- `SESSample.java`: 使用 SigV4 签名发送 Amazon SES 邮件
- `ApiGatewaySample.java`: 使用 SigV4 签名调用 API Gateway
- `BedrockConverseSample.java`: 使用 SigV4 签名调用 Amazon Bedrock

## 运行要求

- Java 17 或更高版本
- Maven 3.6 或更高版本

## 环境变量

在运行代码前，请确保设置以下环境变量：
```bash
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="your-region"  # 可选，默认使用 ap-northeast-1
