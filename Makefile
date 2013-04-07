

all:

install:
	mkdir -pv /usr/local/bin && \
	cp -vf avg_diary.pl avg_diary.sh avg-lyrics /usr/local/bin && \
	cd /usr/local/bin && rm -vf avg-diary && ln -sv ./avg_diary.pl avg-diary
