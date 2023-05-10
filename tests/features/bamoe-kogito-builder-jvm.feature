@ibm-bamoe/bamoe-kogito-builder-rhel8
Feature: rhpam-kogito-builder-rhel8 feature.

  Scenario: verify if the maven and java installation are correct
    When container is started with command bash
    Then run sh -c 'echo $MAVEN_HOME' in container and immediately check its output for /usr/share/maven
    And run sh -c 'echo $MAVEN_VERSION' in container and immediately check its output for 3.8
    And run sh -c 'echo $JAVA_HOME' in container and immediately check its output for /usr/lib/jvm/java-11

  Scenario: verify if all labels are correctly set on rhpam-kogito-builder-rhel8 image
    Given image is built
    # Then the image should not contain label maintainer TODO add support to this sentence on cekit behave steps
    Then the image should contain label io.openshift.s2i.scripts-url with value image:///usr/local/s2i
    And the image should contain label io.openshift.s2i.destination with value /tmp
    And the image should contain label io.openshift.expose-services with value 8080:http
    And the image should contain label io.k8s.description with value IBM BAMOE Platform for building Kogito based on Quarkus or Spring Boot
    And the image should contain label io.k8s.display-name with value IBM build of Kogito builder based on Quarkus or SpringBoot
    And the image should contain label io.openshift.tags with value ibm-bamoe-kogito,builder,kogito,quarkus,springboot
    And the image should contain label io.openshift.s2i.assemble-input-files with value /home/kogito/bin
    And the image should contain label com.redhat.component with value ibm-bamoe-kogito-builder-rhel8-container

  Scenario: verify if prod builder image contains the red hat maven repositories
    When container is started with command bash
    Then file /home/kogito/.m2/settings.xml should contain <id>redhat-maven-repositories</id>
    And file /home/kogito/.m2/settings.xml should contain <activeProfile>redhat-maven-repositories</activeProfile>
    And file /home/kogito/.m2/settings.xml should contain <id>redhat-ga-repository</id>
    And file /home/kogito/.m2/settings.xml should contain <url>https://maven.repository.redhat.com/ga/</url>
    And file /home/kogito/.m2/settings.xml should contain <id>redhat-ea-repository</id>
    And file /home/kogito/.m2/settings.xml should contain <url>https://maven.repository.redhat.com/earlyaccess/all/</url>
    And file /home/kogito/.m2/settings.xml should contain <id>redhat-techpreview-repository</id>
    And file /home/kogito/.m2/settings.xml should contain <url>https://maven.repository.redhat.com/techpreview/all</url>

  Scenario: Check if the expected message is printed if native build is enabled
    Given failing s2i build /tmp/kogito-examples from dmn-example using 1.13.x
      | variable       | value          |
      | RUNTIME_TYPE   | quarkus        |
      | NATIVE         | true           |
      | KOGITO_VERSION | 1.13.1-SNAPSHOT |
    # Then s2i build log should contain does not supports native builds # looks like it does not work ...

  Scenario: Verify that the Kogito Maven archetype is generating the project and compiling it correctly
    Given s2i build /tmp/kogito-examples from dmn-example using nightly-1.13.x-blue and runtime-image ibm-bamoe/bamoe-kogito-runtime-jvm-rhel8:latest
      | variable       | value          |
      | RUNTIME_TYPE   | quarkus        |
      | NATIVE         | false          |
      | KOGITO_VERSION | 1.13.2-SNAPSHOT |
    Then file /home/kogito/bin/quarkus-run.jar should exist
    And s2i build log should contain Generating quarkus project structure for project...
    And s2i build log should contain Using Quarkus com.redhat.quarkus.platform:quarkus-maven-plugin:
    And check that page is served
      | property        | value                                                                                            |
      | port            | 8080                                                                                             |
      | path            | /Traffic%20Violation                                                                             |
      | wait            | 80                                                                                               |
      | expected_phrase | Should the driver be suspended?                                                                  |
      | request_method  | POST                                                                                             |
      | content_type    | application/json                                                                                 |
      | request_body    | {"Driver": {"Points": 2}, "Violation": {"Type": "speed","Actual Speed": 120,"Speed Limit": 100}} |
    And check that page is served
      | property        | value                           |
      | port            | 8080                            |
      | path            | /q/health/live                  |
      | wait            | 80                              |
      | request_method  | GET                             |
      | content_type    | application/json                |
      | request_body    | {"status": "UP", "checks": []}  |

  Scenario: Verify that the Kogito Maven archetype is generating the project and compiling it correctly with custom group id, archetype & version
    Given s2i build /tmp/kogito-examples from dmn-example using nightly-1.13.x-blue and runtime-image ibm-bamoe/bamoe-kogito-runtime-jvm-rhel8:latest
      | variable            | value          |
      | RUNTIME_TYPE        | quarkus        |
      | NATIVE              | false          |
      | KOGITO_VERSION      | 1.13.1-SNAPSHOT |
      | PROJECT_GROUP_ID    | com.mycompany  |
      | PROJECT_ARTIFACT_ID | myproject      |
      | PROJECT_VERSION     | 2.0-SNAPSHOT   |
    Then file /home/kogito/bin/quarkus-run.jar should exist
    And s2i build log should contain Generating quarkus project structure for myproject...
    And check that page is served
      | property        | value                                                                                            |
      | port            | 8080                                                                                             |
      | path            | /Traffic%20Violation                                                                             |
      | wait            | 80                                                                                               |
      | expected_phrase | Should the driver be suspended?                                                                  |
      | request_method  | POST                                                                                             |
      | content_type    | application/json                                                                                 |
      | request_body    | {"Driver": {"Points": 2}, "Violation": {"Type": "speed","Actual Speed": 120,"Speed Limit": 100}} |

#### SpringBoot Scenarios

  Scenario: Verify that the Kogito Maven archetype is generating the project and compiling it correctly when runtime is springboot
    Given s2i build /tmp/kogito-examples from dmn-example using nightly-1.13.x-blue and runtime-image ibm-bamoe/bamoe-kogito-runtime-jvm-rhel8:latest
      | variable            | value                |
      | KOGITO_VERSION | 1.13.2-SNAPSHOT |    
      | RUNTIME_TYPE        | springboot           |
      | MAVEN_ARGS_APPEND   | -Dstarters=decisions |
    Then file /home/kogito/bin/project-1.0-SNAPSHOT.jar should exist
    And s2i build log should contain Generating springboot project structure for project...
    And check that page is served
      | property        | value                                                                                            |
      | port            | 8080                                                                                             |
      | path            | /Traffic%20Violation                                                                             |
      | wait            | 80                                                                                               |
      | expected_phrase | Should the driver be suspended?                                                                  |
      | request_method  | POST                                                                                             |
      | content_type    | application/json                                                                                 |
      | request_body    | {"Driver": {"Points": 2}, "Violation": {"Type": "speed","Actual Speed": 120,"Speed Limit": 100}} |
    And check that page is served
      | property        | value            |
      | port            | 8080             |
      | path            | /actuator/health |
      | wait            | 80               |
      | request_method  | GET              |
      | content_type    | application/json |
      | request_body    | {"status":"UP"}  |