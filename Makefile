CXXFLAGS =	-O2 -g -Wall -fmessage-length=0 $(shell pkg-config gtkmm-2.4 --cflags) $(shell pkg-config exiv2 --cflags)

OBJS =		xmpedit.o MainWindow.o MetadataTreeModel.o

LIBS =		$(shell pkg-config gtkmm-2.4 --libs) $(shell pkg-config exiv2 --libs)

TARGET =	xmpedit

$(TARGET):	$(OBJS)
	$(CXX) -o $(TARGET) $(OBJS) $(LIBS)

all:	$(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)
