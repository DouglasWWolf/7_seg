@echo off
set project=7_seg
git add src/*.* xdc/*.* %project%.srcs/*.* %project%.xpr
git add push.bat README.md
git commit -m "See History.h for changes"
git push origin main