#!/usr/bin/env bash
set -e
G=mg.niaina.gilbert
V=0.0.1-SNAPSHOT

# ---------- POM parent ----------
cat > pom.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>$G</groupId>
  <artifactId>hive-parent</artifactId>
  <version>$V</version>
  <packaging>pom</packaging>

  <modules>
    <module>hive-domain</module>
    <module>hive-algo</module>
    <module>hive-sim</module>
    <module>hive-core</module>
    <module>hive-dashboard</module>
    <module>hive-web</module>
  </modules>

  <properties>
    <maven.compiler.release>17</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <servlet.version>6.1.0</servlet.version>
    <websocket.version>2.2.0</websocket.version>
    <junit.version>5.10.2</junit.version>
    <postgresql.version>42.7.3</postgresql.version>
  </properties>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>jakarta.servlet</groupId>
        <artifactId>jakarta.servlet-api</artifactId>
        <version>\${servlet.version}</version>
        <scope>provided</scope>
      </dependency>
      <dependency>
        <groupId>jakarta.websocket</groupId>
        <artifactId>jakarta.websocket-api</artifactId>
        <version>\${websocket.version}</version>
        <scope>provided</scope>
      </dependency>
      <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <version>\${postgresql.version}</version>
      </dependency>
      <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <version>\${junit.version}</version>
        <scope>test</scope>
      </dependency>
      <dependency><groupId>$G</groupId><artifactId>hive-domain</artifactId><version>\${project.version}</version></dependency>
      <dependency><groupId>$G</groupId><artifactId>hive-algo</artifactId><version>\${project.version}</version></dependency>
      <dependency><groupId>$G</groupId><artifactId>hive-sim</artifactId><version>\${project.version}</version></dependency>
      <dependency><groupId>$G</groupId><artifactId>hive-core</artifactId><version>\${project.version}</version></dependency>
      <dependency><groupId>$G</groupId><artifactId>hive-dashboard</artifactId><version>\${project.version}</version></dependency>
    </dependencies>
  </dependencyManagement>

  <build>
    <pluginManagement>
      <plugins>
        <plugin><artifactId>maven-compiler-plugin</artifactId><version>3.13.0</version></plugin>
        <plugin><artifactId>maven-surefire-plugin</artifactId><version>3.2.5</version></plugin>
        <plugin><artifactId>maven-jar-plugin</artifactId><version>3.4.1</version></plugin>
        <plugin><artifactId>maven-war-plugin</artifactId><version>3.4.0</version></plugin>
      </plugins>
    </pluginManagement>
  </build>
</project>
EOF

# ---------- fonction : crée un module ----------
# usage : module <nom> <packaging> <bloc XML (dépendances, build...)>
module() {
  local name=$1 pack=$2 extra=$3
  mkdir -p "$name/src/main/java" "$name/src/main/resources" "$name/src/test/java"
  cat > "$name/pom.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>$G</groupId>
    <artifactId>hive-parent</artifactId>
    <version>$V</version>
  </parent>
  <artifactId>$name</artifactId>
  <packaging>$pack</packaging>
$extra
</project>
EOF
}

dep()  { echo "<dependency><groupId>$G</groupId><artifactId>$1</artifactId></dependency>"; }
JUNIT='<dependency><groupId>org.junit.jupiter</groupId><artifactId>junit-jupiter</artifactId></dependency>'
SERVLET='<dependency><groupId>jakarta.servlet</groupId><artifactId>jakarta.servlet-api</artifactId></dependency>'
WEBSOCKET='<dependency><groupId>jakarta.websocket</groupId><artifactId>jakarta.websocket-api</artifactId></dependency>'
PG='<dependency><groupId>org.postgresql</groupId><artifactId>postgresql</artifactId></dependency>'

# ---------- modules ----------
module hive-domain jar "  <dependencies>$JUNIT</dependencies>"

module hive-algo jar "  <dependencies>$JUNIT</dependencies>"

module hive-sim jar "  <dependencies>$(dep hive-domain) $JUNIT</dependencies>"

module hive-core jar "  <dependencies>$(dep hive-domain) $(dep hive-algo) $PG $JUNIT</dependencies>"

# dashboard : jar de ressources statiques servies par Tomcat depuis WEB-INF/lib
module hive-dashboard jar ""
mkdir -p hive-dashboard/src/main/resources/META-INF/resources
cat > hive-dashboard/src/main/resources/META-INF/resources/index.html <<'EOF'
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>HIVE</title></head>
<body><canvas id="hive" width="800" height="600"></canvas></body></html>
EOF

# web : le seul WAR, il embarque tous les autres modules
module hive-web war "  <dependencies>
    $(dep hive-domain) $(dep hive-algo) $(dep hive-sim) $(dep hive-core) $(dep hive-dashboard)
    $SERVLET $WEBSOCKET $JUNIT
  </dependencies>
  <build>
    <finalName>hive-web</finalName>
    <plugins><plugin>
      <artifactId>maven-war-plugin</artifactId>
      <configuration><failOnMissingWebXml>false</failOnMissingWebXml></configuration>
    </plugin></plugins>
  </build>"

# i18n : fichiers de messages de départ
cat > hive-web/src/main/resources/messages_fr.properties <<'EOF'
app.title=HIVE - Orchestrateur de flotte
EOF
cat > hive-web/src/main/resources/messages_en.properties <<'EOF'
app.title=HIVE - Fleet orchestrator
EOF

printf 'target/\n.idea/\n*.iml\n.vscode/\n' > .gitignore
echo "Squelette créé. Lance : mvn clean install"