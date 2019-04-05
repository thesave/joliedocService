# The JolieDoc service

The JolieDoc service is a microservice library useful to emit Joliedoc files.
Joliedocs are similar to Javadocs: they are human-readable files (HTML, Markdown, ...) that document a Jolie program.

# Install as a library

Install one-liner

```
curl -sL https://github.com/thesave/joliedocService/raw/master/install.ol > install.ol &&\
jolie install.ol && rm install.ol
```

# Use as a shell program

jolieDocService can be used as a shell program by downloading the [jolieDoc.ol](https://github.com/thesave/joliedocService/blob/master/jolieDoc.ol) file in the same folder where has been launched the install command above.

Usage: `jolie jolieDoc.ol`, use the option `--help` to read the program parameters and options.
