SOURCES = $(wildcard src/*.lua src/protocols/*.lua)
TARGET = hirveserv

all: $(TARGET)

$(TARGET): $(SOURCES)
	lua merge.lua src main.lua > $(TARGET)
	chmod +x $(TARGET)

clean:
	rm -f $(TARGET)
