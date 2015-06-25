cp -r server ../../radstar
cp -r Export/flash/bin/ ../../radstar/games/AI-battle
cd ../../radstar
PAUSE
git add .
git commit -am "pusblish"
git push origin master