# greyscale-toggle

Uses ruby and imagemagick to automate production of greyscale images and toggle between colour and greyscale copies in a `current` folder. For greater image control in greyscale InDesign exports.

```
├── original
├── current
├── greyscale
├── colour
├── watch.rb
└── config.yml
```

When images are added to or updated in `original` they are copied into `colour`, processed and copied into `greyscale`, and the relevant varient copied into `current`.

If you change the `current` mode in `config.yml`, the contents of either the `colour` or `greyscale` folder will be copied into `current`.
