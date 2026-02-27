/* eslint-disable prettier/prettier */
/* eslint-disable @typescript-eslint/no-floating-promises */
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS (Origin: *)
  app.enableCors({
    origin: '*',
    credentials: true,
  });

  // 3. Enable API Versioning (/api/v1/auth/...)
  app.enableVersioning({
    type: VersioningType.URI,
  });


  // Global Prefix (/api)
  app.setGlobalPrefix('api');

    // 4. Global Validation (Filters invalid data before hitting controller)
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true, // Strips properties not in DTO
    forbidNonWhitelisted: true, // Throws error if extra properties sent
    transform: true, // Auto-transforms types
  }));

   // 5. Swagger Setup (Documentation)
  const config = new DocumentBuilder()
    .setTitle('LeadUnity API')
    .setDescription('API documentation for LeadUnity Backend')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);


  await app.listen(process.env.PORT || 5000);
  console.log(`Server running on port ${process.env.PORT || 5000}`);
}
bootstrap();