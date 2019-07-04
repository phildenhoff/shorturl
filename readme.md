# shorturl

Loosely based on @xmonader's [Day 7 of Nim days](https://xmonader.github.io/nimdays/day07_shorturl.html).

This is a url shortening website that takes input website URLs like "https://google.com/search?q=your%20favourite%20website" and distills them down into tiny links like "https://goo.gl/a7fv31".

## Differences from "Nim days"

Databases have their value, but I didn't feel like setting one up. So, first
off, I removed the dependency on SQLite. Unfortunately, I didn't add back in
preservation of the IDs onto disk, so right now it's all stored in memory in
a map (what Nim calls a "table"). Spooooooky 👻

Because I removed SQLite, I also (apparently?) removed the method for
generating IDs for each URL -- it seems like it was generated implcitly by
SQLite, which I'm pretty sure is bad practice, but oh well. To generate the
short paths, I MD5 hashed the request URL plus the current system time in
milliseconds, and took the last 5 characters. I only added the time since I
didn't like the idea of URLs having the same mapping to an ID for all time;
each URL can only be in the map once.

I thought it was pretty hacky to shove a 50+ line HTML page into a Nim source
file, so I moved that into its own file and created `PathFileBackings` to
enumerate valid files for resources paths (e.g. "index.html" for the `/`
route) and `getPageContent` to get the content of each of those pages at
request time. It would be nice to change this in the future so that the
server pre-caches all files into memory at startup and then occasionally
reviews the file backings for changes, but atm that's more work that it's
worth.

Speaking of HTML, I also added a 404 page (it's very basic) and removed the
accidental "submit" feature of the Enter key in the form. Now, if you press
Enter, you just get the shortened URL. Yay! 🎉 
