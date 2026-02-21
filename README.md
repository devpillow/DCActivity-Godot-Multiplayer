To run the project


1. Create app in discord developer portal, get CLIENTID and SECRET, write them in the .env file (follow the example .env.example) + .discordshell

2. Import godot project to Export to html5 with discord_shell.html as Custom Export shell (export all files and rename to 'index')
put them into "public" folder (all files, including index.html) (! godot version 4.4.1)

3. Setting up cloudflare tunnel, URL Mapping root
Terminal `cloudflared tunnel --url http://localhost:{portNumber}`

4. run `node server.js`

5. run Discord Activity and see result (idk if it will work or not lol)
