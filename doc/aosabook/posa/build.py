#!/usr/bin/env python

import envoy
import os

def main(chapters=[], epub=False, pdf=False, html=False, mobi=False, pandoc_epub=False):
    if not os.path.isdir('output'):
        os.mkdir('output')
    else:
        run('rm output/*')
    chapter_dirs = [
            'chrome',
            'ethercalc',
            'ninja',
            'pugixml',
            'memshrink',
            'dance',
            'infinispan',
            'talos',
            'zotonic',
            'mobile-perf',
            'warp',
            'khmer',
            ]
    if len(chapters) > 0:
        chapter_dirs = [
                chapter_dir
                for chapter_dir in
                chapter_dirs
                if chapter_dir in chapters
                ]

    chapter_markdowns = [
            './' + chapter_dir + '/' + chapter_dir + '.markdown'
            for chapter_dir in
            chapter_dirs
            ]

    chapter_markdowns_exist = [
            envoy.run('test -f ' + chapter_markdown).status_code
            for chapter_markdown in
            chapter_markdowns
            ]

    process_chapters = [
            chapter_markdown
            for chapter_markdown, process in
            zip(chapter_markdowns, chapter_markdowns_exist)
            if process == 0
        ]

    chapter_names = [
            getbasename(chapter)
            for chapter in
            chapter_dirs
            ]

    image_paths = [
        './ethercalc/ethercalc-images',
        './warp/warp-images',
        './zotonic/zotonic-images',
        './talos/talos-images',
        './chrome/chrome-images',
        './mobile-perf/mobile-perf-images',
        './pugixml/pugixml-images',
        './infinispan/infinispan-images',
        './khmer/khmer-images',
        './memshrink/memshrink-images',
        './dance/dance-images',
        ]

#run('cp /home/tavish/aosa/posa/dance/chapter.tex /home/tavish/aosa/posa/tex/dance.tex')
#[run("cp /home/tavish/aosa/posa/dance/{f} /home/tavish/aosa/posa/tex/dance{f}".format(f=c)) for c in run('ls ../dance | grep tex$ | grep -v chapter.tex').std_out.splitlines()]

    with open('tex/posa.tex', 'w') as out:
        with open('tex/posa.template.tex') as template:
            lines = template.readlines()
            for line in lines:
                if 'chapterchapterchapter' in line:
                    out.write(
                        "\n".join(
                            "\include{%s}\n" % (chapter_name)
                            for chapter_name in chapter_names
                            )
                        )
                else:
                    out.write(line)

    if pdf:
        for imgpath in image_paths:
            # This is silly but oh well
            run("cp -a {imgpath} tex/".format(imgpath=imgpath))
        texify_chapters = [
            pandoc_cmd(chapter_markdown)
            for chapter_markdown in
            process_chapters
        ]
        build_pdf()

    if epub:
        for imgpath in image_paths:
            # This is silly but oh well
            run("cp -a {imgpath} epub/".format(imgpath=imgpath))
        build_epub(process_chapters, pandoc_epub)

    if mobi and not epub:
        print "Can't build .mobi; depends on .epub."
        print "Use --epub --mobi to build .mobi file."
    elif mobi:
        build_mobi()

    if html:
        for imgpath in image_paths:
            # This is silly but oh well
            run("cp -a {imgpath} html/content/pages/".format(imgpath=imgpath))
        build_html(process_chapters)
        for imgpath in image_paths:
            # So you thought that was silly? Lemme show ya
            run("cp -a {imgpath} html/output/pages/".format(imgpath=imgpath))

def build_pdf():
    os.chdir('tex')
    run('pdflatex -interaction nonstopmode posa')
    run('bibtex posa')
    run('pdflatex -interaction nonstopmode posa')
    run('pdflatex -interaction nonstopmode posa')
    run('pdflatex -interaction nonstopmode posa')
    os.chdir('..')
    run('mv tex/posa.pdf output/')

def build_epub(chapter_markdowns, pandoc_epub):
    basenames = [
            os.path.splitext(
                os.path.split(chapter_markdown)[1]
            )[0] + ".markdown"
            for chapter_markdown in chapter_markdowns ]
    temp = 'python preprocessor.py --chapter {chapnum} --output=epub/{basename}.markdown.1 --latex {md}'
    for i, markdown in enumerate(chapter_markdowns):
        basename = os.path.splitext(os.path.split(markdown)[1])[0]
        run(temp.format(md=markdown, basename=basename, chapnum=i+1))
    os.chdir('epub')
    temp = '../increaseheaders.sh {basename}.markdown.1 {basename}.markdown {chapnum}'
    for i, markdown in enumerate(chapter_markdowns):
        basename = os.path.splitext(os.path.split(markdown)[1])[0]
        run(temp.format(md=markdown, basename=basename, chapnum=i+1))
    pandoc_path = 'pandoc'
    cmd = "{pandoc} --chapters -S -f markdown+mmd_title_block --highlight-style=kate -o posa.epub epubtitle.txt introduction.markdown {markdowns}"
    if pandoc_epub:
        run(cmd.format(pandoc=pandoc_path, markdowns=" ".join(basenames)))
        print cmd.format(pandoc=pandoc_path, markdowns=" ".join(basenames))
    import subprocess as sp
    output = " ".join(open('image-list.txt').read().splitlines())
    print 'zip posa.epub META-INF mimetype nav.xhtml toc.ncx stylesheet.css content.opf ' + output
    sp.check_output(
        'zip posa.epub META-INF mimetype nav.xhtml toc.ncx stylesheet.css content.opf ' + output,
        shell=True)
    if os.path.isdir('tmp-epub-contents'):
        run('rm -r tmp-epub-contents')
    os.mkdir('tmp-epub-contents')
    sp.check_output(
        'unzip posa.epub -d tmp-epub-contents/',
        shell=True,
    )
    sp.check_output(
        'rsync -a tmp-epub-contents/* ./',
        shell=True
    )
    run('rm -r tmp-epub-contents')
    run('cp posa.epub ../output/posa.epub')
    os.chdir('..')

def build_mobi():
    run('ebook-convert output/posa.epub output/posa.mobi')

def build_html(chapter_markdowns):
    run('mkdir -p html/content/pages')
    temp = 'python preprocessor.py --chapter {chap} --html-refs --html-paths --output={md}.1 --latex {md}'
    temp2 = 'pandoc --csl=ieee.csl --bibliography=tex/posa.bib -t html -f markdown+citations -o html/content/pages/{basename}.md {md}.1'
    temp3 = './fix_html_title.sh html/content/pages/{basename}.md'
    for i, markdown in enumerate(chapter_markdowns):
        basename = os.path.splitext(os.path.split(markdown)[1])[0]
        run(temp.format(chap=i+1, md=markdown, basename=basename))
        run(temp2.format(md=markdown, basename=basename))
        run(temp3.format(md=markdown, basename=basename))
    os.chdir('html')
    run('make html')
    os.chdir('..')

def getbasename(chapter_markdown):
    import os
    basename = os.path.splitext(
            os.path.split(chapter_markdown)[1]
            )[0]
    return basename

def _pandoc_cmd(chapter_markdown):
    pandoc_path = 'pandoc'
    temp = '{pandoc} -V chaptertoken={chaptertoken} -t latex --chapters -S -f markdown+mmd_title_block+tex_math_dollars --template=tex/chaptertemplate.tex -o tex/{basename}.tex.1 tex/{md}' # tex/md because that's where the preprocessed markdowns end up
    basename = getbasename(chapter_markdown)
    result = temp.format(pandoc=pandoc_path, basename=basename, md=chapter_markdown, chaptertoken='s:' + basename)
    return result

def preprocessor_command(chapter_markdown):
    temp = 'python preprocessor.py --output=tex/{basename}.markdown --markdown {md}'
    basename = getbasename(chapter_markdown)
    result = temp.format(basename=basename, md=chapter_markdown)
    print result
    return (result, basename)

def postprocessor_command(basename):
    temp = 'python postprocessor.py --output=tex/{basename}.tex tex/{basename}.tex.1'
    return temp.format(basename=basename)

def pandoc_cmd(chapter_markdown):
    cmd, basename = preprocessor_command(chapter_markdown)
    result = envoy.run(cmd)
    new_chapter_markdown = basename + '.markdown'
    if result.status_code != 0:
        print result.std_err
    else:
        print result.std_out
    result = envoy.run(_pandoc_cmd(new_chapter_markdown))
    if result.status_code != 0:
        print result.std_err
    else:
        print result.std_out
    result2 = envoy.run(postprocessor_command(basename))
    return result2

def run(cmd):
    print cmd
    result = envoy.run(cmd)
    print result.std_out
    print result.std_err
    return result

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('chapters', nargs='*')
    parser.add_argument('--epub', action='store_true', default=False)
    parser.add_argument('--mobi', action='store_true', default=False)
    parser.add_argument('--pdf', action='store_true', default=False)
    parser.add_argument('--html', action='store_true', default=False)
    parser.add_argument('--pandoc-epub', action='store_true', default=False)
    args = parser.parse_args()
    main(chapters=args.chapters, epub=args.epub, pdf=args.pdf, html=args.html, mobi=args.mobi, pandoc_epub=args.pandoc_epub)
