#!/usr/bin/env bash

# Install node_modules, if not already installed
if [ ! -r ./node_modules ]; then
    echo "Installing node_modules..."
    podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'npm ci'
fi

# Install m30mlTools/node_modules, if not already installed
if [ ! -r ./m30mlTools/node_modules ]; then
    echo "Installing m30mlTools/node_modules..."
    podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'cd m30mlTools && npm ci'
fi

# Install dof-helpers/node_modules, if not already installed
if [ ! -r ./dof-helpers/node_modules ]; then
    echo "Installing dof-helpers/node_modules..."
    podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'cd dof-helpers && npm ci'
fi

# Create dist/ directory, if none exists
if [ ! -r ./dist ]; then
    echo "Creating dist/ directory..."
    mkdir dist/
fi

# copy operating-mode-as-fsm.puml to dist/...
echo "copying operating-mode-as-fsm.puml to dist/..."
podman run --rm -v $PWD:/src -w /src docker.io/node bash -c 'cp ./components/sealion-cubesat/components/sealion-obc/components/dilophos/fsw-architecture/operating-mode-as-fsm.puml dist/'

# generate dist/component.yaml & symlink to architecture/ directory
echo "generating dist/component.yaml & symlink to architecture/ directory..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'node dof-helpers/parseComponent.js && mkdir architecture/4-Components && ln -srv dist/component.yaml architecture/4-Components'

# Build the unified model
echo "Building the unified model..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'node m30mlTools/buildUnifiedModel.js && cp dist/architecture.yaml dist/architecture.yml'

# generate stakeholder needs mapping
echo "generating stakeholder needs mapping..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'node m30mlTools/generateDoc.js --unifiedModel=dist/architecture.yaml --template=templates/stakeholder-needs-mapping.puml.liquid --out=dist/stakeholder-needs-mapping.puml'

# generate user stories mapping
echo "generating user stories mapping..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'node m30mlTools/generateDoc.js --unifiedModel=dist/architecture.yaml --template=templates/user-stories-mapping.puml.liquid --out=dist/user-stories-mapping.puml'

# generate use-case-diagrams.puml from liquid template
echo "generating use-case-diagrams.puml from liquid template..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'node m30mlTools/generateDoc.js --unifiedModel=dist/architecture.yaml --template=templates/use-case-diagram.puml.liquid --out=dist/use-case-diagram.puml'

# generate data structure mapping
echo "generating data structure mapping..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'node m30mlTools/generateDoc.js --unifiedModel=dist/architecture.yaml --template=templates/data-structures-mapping.puml.liquid --out=dist/data-structures-mapping.puml'

# generate sealion-mission-architecture.adoc from liquid template
echo "generating sealion-mission-architecture.adoc from liquid template..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'node m30mlTools/generateDoc.js --unifiedModel=dist/architecture.yaml --template=templates/sealion-mission-architecture.adoc.liquid --out=dist/sealion-mission-architecture.adoc'

# generate pdf-theme.yml from liquid template
echo "generating pdf-theme.yml from liquid template..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/capsulecorplab/asciidoctor-extended:liquidoc 'bundle exec liquidoc -d dist/architecture.yml -t templates/pdf-theme.yml.liquid -o dist/pdf-theme.yml'
#podman run --rm --volume "$PWD:/src" -w "/src" node bash -c 'bundle exec liquidoc -d dist/architecture.yml -t templates/pdf-theme.yml.liquid -o dist/pdf-theme.yml'

# generate index.html
echo "generating index.html..."
podman run --rm --volume $PWD:/src -w "/src" docker.io/asciidoctor/docker-asciidoctor asciidoctor dist/sealion-mission-architecture.adoc -r asciidoctor-diagram -o dist/index.html

# generate sealion-mission-architecture.pdf
echo "generating sealion-mission-architecture.pdf..."
podman run --rm --volume $PWD:/src -w "/src" docker.io/asciidoctor/docker-asciidoctor asciidoctor dist/sealion-mission-architecture.adoc -o dist/sealion-mission-architecture.pdf -r asciidoctor-pdf -r asciidoctor-diagram -b pdf -a pdf-theme=dist/pdf-theme.yml

# remove architecture/4-Components
echo "removing architecture/4-Components..."
podman run --rm --volume $PWD:/src -w "/src" docker.io/node bash -c 'rm -rf architecture/4-Components'

## Generate presentation.html
#echo "Generating presentation.adoc..."
#podman run --rm -v $PWD:/src -w /src node node m30mlTools/generateDoc.js --unifiedModel=dist/architecture.yaml --template=templates/presentation.adoc.liquid --out=dist/presentation.adoc
#echo "Generating presentation.html..."
#podman run --rm -v $PWD:/documents asciidoctor/docker-asciidoctor bash -c "cd dist && asciidoctor-revealjs -r asciidoctor-diagram -a revealjsdir=https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.8.0 -a revealjs_transition=slide -a revealjs_slideNumber=true -a revealjs_width=1100 -a revealjs_height=700 -D . 'presentation.adoc' -o 'presentation.html'"

# generate tabulated-stakeholder-needs.adoc from liquid template for extended abstract
echo "generating tabulated-stakeholder-needs.adoc from liquid template..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'node m30mlTools/generateDoc.js --unifiedModel=dist/architecture.yaml --template=templates/tabulated-stakeholder-needs.adoc.liquid --out=dist/tabulated-stakeholder-needs.adoc'

## create symbolic link for tabulated-stakeholder-needs.adoc
#echo "create symbolic link for tabulated-stakeholder-needs.adoc in research/..."
#podman run --rm --volume "$PWD:/src" -w "/src" node bash -c 'ln -srv dist/tabulated-stakeholder-needs.adoc research/tabulated-stakeholder-needs.adoc'

# generate tabulated-user-stories.adoc from liquid template for extended abstract
echo "generating tabulated-user-stories.adoc from liquid template..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'node m30mlTools/generateDoc.js --unifiedModel=dist/architecture.yaml --template=templates/tabulated-user-stories.adoc.liquid --out=dist/tabulated-user-stories.adoc'

## create symbolic link for tabulated-user-stories.adoc
#echo "create symbolic link for tabulated-user-stories.adoc in research/..."
#podman run --rm --volume "$PWD:/src" -w "/src" node bash -c 'ln -srv dist/tabulated-user-stories.adoc research/tabulated-user-stories.adoc'

# generate satellite-health-data.adoc from liquid template for extended abstract
echo "generating satellite-health-data.adoc from liquid template..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'node m30mlTools/generateDoc.js --unifiedModel=dist/architecture.yaml --template=templates/satellite-health-data.adoc.liquid --out=dist/satellite-health-data.adoc'

## create symbolic link for satellite-health-data.adoc
#echo "create symbolic link for satellite-health-data.adoc in research/..."
#podman run --rm --volume "$PWD:/src" -w "/src" node bash -c 'ln -srv dist/satellite-health-data.adoc research/satellite-health-data.adoc'

# generate abstract.html from liquid template for extended abstract
echo "generating abstract.html..."
podman run --rm --volume $PWD:/src -w "/src" docker.io/asciidoctor/docker-asciidoctor asciidoctor research/abstract.adoc -o dist/abstract.html -r asciidoctor-pdf -r asciidoctor-diagram -r asciidoctor-bibtex

# generate abstract.pdf from liquid template for extended abstract
echo "generating abstract.pdf..."
podman run --rm --volume $PWD:/src -w "/src" docker.io/asciidoctor/docker-asciidoctor asciidoctor research/abstract.adoc -o dist/abstract.pdf -r asciidoctor-pdf -r asciidoctor-diagram -r asciidoctor-bibtex -b pdf

#### generate LaTeX code for satellite health data packet table ####
echo "generating satellite-health-data-packet.tex from liquid template..."
podman run --rm --volume "$PWD:/src" -w "/src" docker.io/node bash -c 'node m30mlTools/generateDoc.js --unifiedModel=dist/architecture.yaml --template=templates/satellite-health-data-packet-as-table.tex.liquid --out=dist/satellite-health-data-packet-as-table.tex'

#### set environment variable for project root ####
project_root=$PWD

#### generate example manuscript ####
# for linkml podman command usage, see https://hub.podman.com/r/linkml/linkml

clitool="linkml-validate"
cmdargs="-s manuscript-metamodel.yaml manuscript-example.yaml"
cmd="$clitool $cmdargs"
workdir=$project_root/manuscript
podmancmd="podman run --rm -v $workdir:/work -w /work docker.io/linkml/linkml:1.3.14 $cmd"
condition="$clitool --help | grep 'Validates instance data' > /dev/null"

if ! eval $condition; then
    echo "Validating linkml model of example manuscript via podman..."
    cd $project_root
    eval $(echo $podmancmd)
else
    echo "Validating linkml model of example manuscript..."
    cd $workdir
    eval $cmd
fi

clitool="jinja2"
cmdargs="-o dist/manuscript-example.tex --format yaml templates/manuscript.tex.jinja2 manuscript/manuscript-example.yaml"
workdir=$project_root
#cmdargs="-o dist/title.tex --format yaml templates/title.tex.jinja2 manuscript/manuscript-example.yaml"
cmd="$clitool $cmdargs"
podmancmd="podman run --rm -v $workdir:/work -w /work docker.io/roquie/docker-jinja2-cli $cmdargs"
condition="$clitool --version | grep 'v0.8.2' > /dev/null"

if ! eval $condition; then
    echo "Generating LaTeX document from example manuscript linkml model and jinja2 template via podman..."
    cd $project_root
    eval $(echo $podmancmd)
else
    echo "Generating LaTeX document from example manuscript linkml model and jinja2 template..."
    cd $workdir
    eval $cmd
fi

echo "Copy LaTeX files and assets (required for generating PDF document) to dist/..."

cd $project_root
cp -t dist/ manuscript/*.tex manuscript/*.bib manuscript/*.bst manuscript/*.cls assets/*

# https://tex.stackexchange.com/questions/43325/citations-not-showing-up-in-text-and-bibliography
cmd="pdflatex manuscript-example.tex && bibtex manuscript-example.aux"
workdir=$project_root/dist
podmancmd="podman run --rm -v $workdir:/srv -w /srv docker.io/nanozoo/pdflatex:3.14159265--f2f4a3f bash -c '$cmd'"

if [ ! $(pdflatex -version | grep '3.14159265-2.6-1.40.19' > /dev/null) ] && [ ! $(bibtex -version | grep '0.99d' > /dev/null) ]; then
    echo "Pre-Processing LaTeX document with BibTeX of example manuscript via podman..."
    cd $project_root
    eval $(echo $podmancmd)
else
    echo "Pre-Processing LaTeX document with BibTeX of example manuscript..."
    cd $workdir
    eval $cmd
fi

# https://tex.stackexchange.com/questions/43325/citations-not-showing-up-in-text-and-bibliography
cmd="pdflatex manuscript-example.tex && pdflatex manuscript-example.tex"
workdir=$project_root/dist
podmancmd="podman run --rm -v $workdir:/srv -w /srv docker.io/nanozoo/pdflatex:3.14159265--f2f4a3f bash -c '$cmd'"

if [ ! $(pdflatex -version | grep '3.14159265-2.6-1.40.19' > /dev/null) ] && [ ! $(bibtex -version | grep '0.99d' > /dev/null) ]; then
    echo "Generating PDF document from LaTeX/BibTeX document of example manuscript via podman..."
    cd $project_root
    eval $(echo $podmancmd)
else
    echo "Generating PDF document from LaTeX/BibTeX document of example manuscript..."
    cd $workdir
    eval $cmd
fi

#### generate manuscript ####
# for linkml podman command usage, see https://hub.podman.com/r/linkml/linkml

clitool="linkml-validate"
cmdargs="-s manuscript-metamodel.yaml manuscript.yaml"
cmd="$clitool $cmdargs"
workdir=$project_root/manuscript
podmancmd="podman run --rm -v $workdir/manuscript:/work -w /work docker.io/linkml/linkml:1.3.14 $cmd"
condition="$clitool --help | grep 'Validates instance data' > /dev/null"

if ! eval $condition; then
    echo "Validating linkml model of manuscript via podman..."
    cd $project_root
    eval $(echo $podmancmd)
else
    echo "Validating linkml model of manuscript..."
    cd $workdir
    eval $cmd
fi

clitool="jinja2"
cmdargs="-o dist/manuscript.tex --format yaml templates/manuscript.tex.jinja2 manuscript/manuscript.yaml"
#cmdargs="-o dist/title.tex --format yaml templates/title.tex.jinja2 manuscript/manuscript.yaml"
cmd="$clitool $cmdargs"
workdir=$project_root
podmancmd="podman run --rm -v $workdir:/work -w /work docker.io/roquie/docker-jinja2-cli $cmdargs"
condition="$clitool --version | grep 'v0.8.2' > /dev/null"

if ! eval $condition; then
    echo "Generating LaTeX document from manuscript linkml model and jinja2 template via podman..."
    cd $project_root
    eval $(echo $podmancmd)
else
    echo "Generating LaTeX document from manuscript linkml model and jinja2 template..."
    cd $workdir
    eval $cmd
fi

echo "Copy LaTeX files and assets (required for generating PDF document) to dist/..."

cd $project_root
cp -t dist/ manuscript/*.tex manuscript/*.bib manuscript/*.bst manuscript/*.cls assets/*

# https://tex.stackexchange.com/questions/43325/citations-not-showing-up-in-text-and-bibliography
cmd="pdflatex manuscript.tex && bibtex manuscript.aux"
workdir=$project_root/dist
podmancmd="podman run --rm -v $workdir:/srv -w /srv docker.io/nanozoo/pdflatex:3.14159265--f2f4a3f bash -c '$cmd'"

if [ ! $(pdflatex -version | grep '3.14159265-2.6-1.40.19' > /dev/null) ] && [ ! $(bibtex -version | grep '0.99d' > /dev/null) ]; then
    echo "Pre-Processing LaTeX document with BibTeX of manuscript via podman..."
    cd $project_root
    eval $(echo $podmancmd)
else
    echo "Pre-Processing LaTeX document with BibTeX of manuscript..."
    cd $workdir
    eval $cmd
fi

# https://tex.stackexchange.com/questions/43325/citations-not-showing-up-in-text-and-bibliography
cmd="pdflatex manuscript.tex && pdflatex manuscript.tex"
workdir=$project_root/dist
podmancmd="podman run --rm -v $workdir:/srv -w /srv docker.io/nanozoo/pdflatex:3.14159265--f2f4a3f bash -c '$cmd'"

if [ ! $(pdflatex -version | grep '3.14159265-2.6-1.40.19' > /dev/null) ] && [ ! $(bibtex -version | grep '0.99d' > /dev/null) ]; then
    echo "Generating PDF document from LaTeX/BibTeX document of manuscript via podman..."
    cd $project_root
    eval $(echo $podmancmd)
else
    echo "Generating PDF document from LaTeX/BibTeX document of manuscript..."
    cd $workdir
    eval $cmd
fi

gitdescribe=$(git describe --always --tags HEAD)
newmanuscriptname=manuscript-$gitdescribe.pdf
mv $workdir/manuscript.pdf $workdir/$newmanuscriptname

#### generate manuscript ####
# Copy scitech-presentation.adoc to dist/
cp -t dist/ manuscript/scitech-presentation.adoc assets/* -r themes/

# Generate scitech-presentation.html
echo "Generating scitech-presentation.html..."
podman run --rm -v $project_root/dist:/documents docker.io/asciidoctor/docker-asciidoctor asciidoctor-revealjs -r asciidoctor-diagram -a revealjs_transition=slide -a revealjs_slideNumber=true -a revealjs_width=1100 -a revealjs_height=700 'scitech-presentation.adoc' -o 'scitech-presentation.html'

# Copy reveal.js to dist/
cp -r reveal.js/ dist/
