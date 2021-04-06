# [solar2dplayground.com](https://www.solar2dplayground.com/)

Solar2D Playground is an interactive website that allows you to create and run Solar2D projects instantly online.

This website ws developed and is maintained by [Eetu Rantanen](https://www.erantanen.com).

You can find more of my personal game related projects over at my portfolio site: [www.xedur.com](https://www.xedur.com). I work on all sorts of interesting projects in my free time, especially for Solar2D. If you like what I'm doing, then [consider buying me a cup of coffee over at Ko-fi](https://ko-fi.com/xedur).

<a href="https://ko-fi.com/xedur" rel="Support me">![Foo](https://www.solar2dplayground.com/img/support-me.png)</a>

## Playground limitations & Solar2D:
Solar2D's HTML5 builds are still in beta. This means that some mobile browsers aren't supported and certain features aren't useable on Solar2D Playground. A few features, such as physics, also behave slightly differently on HTML5 builds (for now at least) compared to other platforms. This website is also hosted on GitHub Pages, which poses issues with CORS, etc. This means that you are limited to only using the assets that are included in Solar2D Playground.

If you wish to develop games and apps without limitations, then [download Solar2D](https://solar2d.com/), a fantastic, free, and open source game engine.

Solar2D development is sponsored by its users. Support the project on [GitHub Sponsors](https://github.com/sponsors/shchvova) or [Patreon](https://www.patreon.com/shchvova).

---

In true open source spirit, the entire [Solar2D Playground source](https://github.com/XeduR/solar2dplayground.com) is available under the MIT License.

----

## Notes on developing for Solar2D Playground

1. The source files for Solar2D Playground are not available on the Solar2D subdomain's repository. The source files can be found at [the main repository](https://github.com/XeduR/solar2dplayground.com/).
2. If you have your own sample projects that you'd like to have added to the Playground, you can reach out to me via [Solar2D's official Discord channel](https://discord.gg/QTD4g4w) or send me an email (check email from my GitHub profile). If you want to create sample projects for your own fork, then you can utilise the [FileToJSON](https://github.com/XeduR/solar2dplayground.com/tree/gh-pages/app-source/source/fileToJSON) project located within the repository to format your project into a compact string, which you can then add to the `demos.json` file that gets automatically loaded with the Playground.
3. When building the playground using Solar2D Simulator, make sure that you check `Include Standard Resources ✔️` because they are needed for Widgets to work. Then make sure that `Create FB Instant archive ❌` is deselected.
4. Certain Solar2D Playground features, like copying asset filepath and name to clipboard, requires the app to remain active. Currently Solar2D's HTML5 builds, however, freeze by default if user clicks outside of the app. This default behaviour can be bypassed by
    1. First building the playground app and then unzipping the `playground.bin` file.
    2. Open `coronaHtml5App.js` and search for function `_emscripten_set_blur_callback(target,userData,useCapture,callbackfunc){JSEvents.registerFocusEventCallback(target,userData,useCapture,callbackfunc,12,"blur");return 0}`.
    3. Remove the following code from the function: `JSEvents.registerFocusEventCallback(target,userData,useCapture,callbackfunc,12,"blur");`.
    4. After you've removed it, the remaining function should look like: `function _emscripten_set_blur_callback(target,userData,useCapture,callbackfunc){return 0}`.
    5. Then add the two files back to .bin archive and you are done!
7. If you have any questions and suggestions concerning Solar2D Playground, feel free to get in touch!
