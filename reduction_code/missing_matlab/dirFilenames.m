function filenames=dirFilenames(dirinput)
        files=dir(dirinput);
        filenames={files.name}';
end