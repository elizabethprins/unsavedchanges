# Unsaved changes example

A POC for showing an "unsaved changes" warning when a user tries to leave a page, either by clicking a link or the browser's 'back' or 'forward' buttons. This can be useful on pages with forms, or in other instances where navigating to another page will destroy a user's work. 

All internal links are handled in Elm, and navigation by the browser's 'back' or 'forward' is handled with a popstate event listener and communicated through ports.

Navigation is not blocked when a user clicks the browser's 'refresh' button.


## Includes

1. [Livereload](https://github.com/napcs/node-livereload)
2. [Serve](https://github.com/zeit/serve/)
3. [Sass](https://sass-lang.com/install)

## Getting started

* `make deps` - Install dependencies
* `make` - Compile all Elm and Scss files
* `make watch` - Start livereload and serve app, makes use of [entr](https://formulae.brew.sh/formula-linux/entr)
* `make build` - Build for production
