Intro
=====

<b>Disclaimer: This is a proof of concept implementation.  Google Scholar
does not allow robot access to their page.  They might ban you from
their services.</b>

This library defines some functions to scrape google scholar search
results automatically.  `scrape-scholar-search` takes a query string,
runs it by google scholar and extracts some information about the
first result:
- number of articles that cited the result
- list of articles that cited the result

The return value is a property list like this:

```
(:title ...
 :cited-by-number ...
 :cited-by-link ...
 :cited-bys ((: title ...
 ...
 )))
 ```

Dependencies:
[http://edward.oconnor.cx/elisp/scrape.el](scrape.el)
