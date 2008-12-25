CXXFLAGS = -O2 -g -Wall -fmessage-length=0 $(shell pkg-config gtkmm-2.4 --cflags) $(shell pkg-config exiv2 --cflags)
LDFLAGS = -Wl,-O1 -Wl,--as-needed
OBJS = xmpedit.o MainWindow.o MetadataTreeModel.o
LIBS = $(shell pkg-config gtkmm-2.4 --libs) $(shell pkg-config exiv2 --libs)
TARGET = xmpedit

$(TARGET): $(OBJS)
	$(CXX) $(LDFLAGS) -o $(TARGET) $(OBJS) $(LIBS)

xmpedit.o: xmpedit.cpp MainWindow.h

MainWindow.o: MainWindow.cpp MainWindow.h MetadataTreeModel.h

MetadataTreeModel.o: MetadataTreeModel.cpp MetadataTreeModel.h

.PHONY: all
all: $(TARGET)

.PHONY: clean
clean:
	rm -f $(OBJS) $(TARGET)
