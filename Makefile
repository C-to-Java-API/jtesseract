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
C_API_INCLUDE_DIR = /usr/local/Cellar/tesseract/$(VERSION)/include
C_API_FILE = $(C_API_INCLUDE_DIR)/tesseract/capi.h

STDLIB_INCLUDE = /usr/include
ifeq ($(UNAME_S), Darwin)
	STDLIB_INCLUDE = /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include
endif


all: clean uninstall-deps install-deps jar

install-deps:
	brew install tesseract tesseract-lang

uninstall-deps:
	brew uninstall --ignore-dependencies --force tesseract tesseract-lang

java-src: clean
	jextract --source -t $(package) -I $(STDLIB_INCLUDE) $(CFLAGS) --header-class-name c_api --output $(JAVA_SOURCES_PATH) $(args) $(C_API_FILE)

jar: java-src
	mvn clean package -Dversion=$(VERSION) -Dos=$(PLATFORM) -Darch=$(ARCH)

release: jar
	mvn --batch-mode deploy -Dversion=$(VERSION) -Dos=$(PLATFORM) -Darch=$(ARCH)

clean:
	rm -fr $(BUILD_DIR)
	mvn clean -Dversion=$(VERSION)
