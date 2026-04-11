# Giai đoạn 1: BUILD (Dùng Maven để đóng gói code thành file .jar)
FROM maven:3.8.5-openjdk-17 AS build
WORKDIR /app
# Copy file cấu hình Maven trước để tận dụng cache, giúp build nhanh hơn ở các lần sau
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy toàn bộ code vào và thực hiện đóng gói (bỏ qua chạy thử test cho nhanh)
COPY src ./src
RUN mvn package -DskipTests

# Giai đoạn 2: RUN (Chỉ lấy file .jar sang một môi trường siêu nhẹ)
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
# Lấy file thành phẩm từ giai đoạn 'build' sang
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

HEALTHCHECK CMD curl --fail http://localhost:8080 || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]