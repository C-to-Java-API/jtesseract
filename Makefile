LIB = tesseract
CFLAGS = $(shell pkg-config --cflags $(LIB))

BUILD_DIR = build
UNAME_S = $(shell uname -s)
ARCH = $(shell uname -m)
PLATFORM = linux
ifeq ($(UNAME_S),Darwin)
	PLATFORM = macos
endif
VERSION = $(shell pkg-config --modversion tesseract)
JAR_NAME = $(LIB).$(VERSION).$(PLATFORM).$(ARCH)
JAVA_SOURCES_PATH = $(BUILD_DIR)/src/main/java

INCLUDE_FLAGS = $(shell pkg-config --cflags tesseract)
C_API_INCLUDE_DIR = $(shell brew --cellar)/tesseract/$(VERSION)/include
C_API_FILE = $(C_API_INCLUDE_DIR)/tesseract/capi.h

STDLIB_INCLUDE = /usr/include
ifeq ($(UNAME_S), Darwin)
	STDLIB_INCLUDE = /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include
endif

MAVEN_FLAGS = -Dversion=$(VERSION) -Dos=$(PLATFORM) -Darch=$(ARCH) -Dclassifiers=$(PLATFORM)

all: clean uninstall-deps install-deps jar

jtesseract-src:
	jextract --source -t $(package) -I $(STDLIB_INCLUDE) $(CFLAGS) --header-class-name c_api --output $(JAVA_SOURCES_PATH) $(args) $(C_API_FILE)

jtesseract-dump:
	$(MAKE) jtesseract-src package=jtesseract args='--dump-includes $(dumpfile)'
	grep $(C_API_FILE) $(dumpfile) >> diff.txt

install-deps:
	brew install pkg-config tesseract tesseract-lang

uninstall-deps:
	brew uninstall --ignore-dependencies --force tesseract tesseract-lang

java-src: clean
	$(MAKE) jtesseract-dump dumpfile=jtesseract_dump.txt
	$(MAKE) jtesseract-src package=jtesseract args="@diff.txt"

jar: java-src
	mvn clean package $(MAVEN_FLAGS)

deploy-jar: jar
	mvn deploy:deploy-file \
		  -DgroupId=clang \
		  -DartifactId=jtesseract \
		  -Dpackaging=jar \
		  -Dfile=target/jtesseract.$(VERSION)-$(PLATFORM).jar \
		  -DrepositoryId=github \
		  -Durl=https://maven.pkg.github.com/c-to-java-api/jtesseract \
		  -Dversion=$(VERSION)-$(PLATFORM)

clean:
	rm -fr *.txt
	rm -f *-$(PLATFORM).xml
	rm -f *-$(PLATFORM).jar
	rm -fr $(BUILD_DIR)
	mvn clean $(MAVEN_FLAGS)
