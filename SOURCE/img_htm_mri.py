# SA: 
# Changes:
# 1) The original script puts the images (of left and right brain) side by side 
# this version changes that to a single column print of those images 
# 2) Also the original script uses the whole file name, which in case of the slicesdir 
#    rubbish due to sloppy config of slicesdir. 
#    Here, I use the following naming convention:
#    sub-$StudyID.$SiteID.$SubID_ses-$SesID_run-$RunID
#    This is later should be used when the csv files are generated. 
# SA, Ox, 2019

# #! /usr/bin/python3

#
# Copyright 2019 Medical Research Council Harwell.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#/

"""
Given a directory of images, create orthogonal mid-section slices and put links in a html file.

Currently does not search subdirectories
"""

from pathlib import Path
from typing import List
import os 

__author__ = 'Henrik Westerberg, Aaron McCoy, Daniel Delbarre, Neil Horner'
__credits__ = ['Henrik Westerberg', 'Aaron McCoy', 'Daniel Delbarre', 'Neil Horner']
__license__ = "Apache 2.0"
__maintainer__ = 'Henrik Westerberg'
__email__ = 'h.westerberg@har.mrc.ac.uk'
__status__ = 'Dev'

IMG_EXTS = ['.png', '.jpg']
OUTFILE_NAME = 'imgs.html'

def run(in_dir: Path, out_dir: Path, n_cols: int, num_imgs: int, study_name):
    """

    Parameters
    ----------
    ins_dir
        Folder of input images

    out_dir
        root directory for output

    """

    imgs = []
    subjects = []
    i = 0

    for img_path in sorted(in_dir.iterdir()):
        i += 1
        if img_path.suffix not in IMG_EXTS:
            continue
        imgs.append(img_path)

        if img_path.stem.rsplit('_', 1)[0] not in subjects:
            subjects.append(img_path.stem.rsplit('_', 1)[0])

    for i in range(0, len(imgs, ), num_imgs):
        html_out_path = out_dir / "{}.html".format(i)
        print("+_+_+_+_ Results will be saved in: " + str(html_out_path))
#        write_html(imgs[i: i + num_imgs], html_out_path, subjects[int(i / 2): int((i + num_imgs) / 2)], n_cols, i, study_name)
        print(len(imgs[i: i + num_imgs]))
        print(len(subjects[i: i + num_imgs])) 
        write_html(imgs[i: i + num_imgs], html_out_path, subjects[i: i + num_imgs], n_cols, i, study_name)
#	write_html(imgs, html_out_path, subjects, n_cols, i, study_name)

def write_html(imgs: List, outpath: Path, subjects: List, n_cols, i, study_name):
    h = []

    h.append('<html><body>')

    width = 90 / n_cols

    counter = 0

    for subject in subjects:

        # This look a bit shitty, but as long we are BIDS complaint, it should be safe/fince    
	# Remember, we have our own slicesdir version which now produces stuff as the following example:
	# /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/qc/slicesdir_test/slicesdir//IMG_sub-CFTY720D2201.0063.00012_ses-V5_T1_biascorr.png
	# which basically is: SUBID_SESSIONID_IMAGE-BASENAME.png

        [tmp_path,tmp_file] = os.path.split(subject)

#        print(tmp_file)

        SubID=tmp_file.split("_")[1]
        SesID=tmp_file.split("_")[2]

        subjectcap=SubID+"_"+SesID

        h.append("""
                 <figure>
                 <img src='{}' height=300px>
                 <figcaption>{}</figcaption>
                 <div><a href="#" class="func" data-type="pass">PASSED</a> | <a href="#" class="func" data-type="fail" tabIndex="-1">FAILED</a> | <a href="#" class="func" data-type="negative" tabIndex="-1">TENTATIVE</a> | <a href="#" class="func" data-type="positive" tabIndex="-1">CHECK</a></div>
                 </figure>
                """.format(imgs[counter], subjectcap)) 
        counter = counter + 1

    h.append(
        '<hr/><div id="links"><a href="#" id="done" class="func">Done</a><a href="#" id="saveAll" style="display: none">Save all files </a></div>')

    with open(outpath, 'w') as fh:
        fh.write('\n'.join(h))
        fh.write(get_css().format(width))
        fh.write(get_js(i,study_name))
        fh.write('</body></html>')


def get_css():
    css = """<style>
    body{{font-family: Arial}}
    .title{{width: 100%; padding: 20px; background-color: lightblue; margin-bottom: 20px}}
    .chart_img{{width: 400px}}
    .organ_img{{padding: 10; display: inline-block}}
    .clear{{clear: both}}
    figure{{
        float: left;
        width: {}%;
        text-align: center;
        text-indent: 0;
        border: 3px solid lightgray;
        margin: 0.5em;
        padding: 0.5em;
    }}
    figcaption{{margin: 5px 0; clear: both; padding-top: 5px;}}
    figure img{{
        height: auto;
        display: inline;
        width: 100%;
        float: center;
    }}

    img.scaled {{
        width: 100%;
    }}
    .func{{
        display: inline-block;
        color: #1b1b1b;
        font-size: 12px;
        text-decoration: none;
        background: #d2d2d2;
        border-radius: 4px;
        padding: 5px 5px;
        margin: 0 1px 10x;
    }}
    .func.active{{ color: #fff; }}
    #done.func.active{{ color: #000; }}
    .func:hover{{ background: #b3b3b3; }}
    figure.pass{{border-color: green;}}
    figure.pass .active{{background: green;}}
    figure.fail{{border-color: red}}
    figure.fail .active{{background: red;}}
    figure.positive{{border-color: orange}}
    figure.positive .active{{background: orange;}}
    figure.negative{{border-color: blue}}
    figure.negative .active{{background: blue;}}
    hr{{clear: both;}}
    #links a{{display: inline-block; margin-right: 10px; text-decoration: none;}}
    #downloads {{padding-top: 10px;}}
    a.func.download {{ background: #076aff; color: #fff; }}
    a.func.download:hover {{ background: #0d60dc; }}
    </style>"""
    return css


def get_js(i,study_name):
    js = """<script>/*-------Declare arrays------*/
            var positive = [],
                negative = [],
                pass = [],
                fail = [],
                arrs = [positive, negative, pass, fail];

            // Get html elements
            var filenames = document.getElementsByTagName("figcaption");
            var btns = document.getElementsByClassName("func");
            var done = document.getElementById("done");
            var saveAll = document.getElementById('saveAll');

            //add files to pass as default
            //for(i = 0; i < filenames.length; i++){
            //    pass.push(filenames[i].innerText);
            //}

            //print out link to each text file
            var printArrays = function(arr, name){

                var element = document.createElement('a');
                element.classList.add('func', 'download');

                element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(arr));
                element.setAttribute('download', name);
                element.innerHTML= name;

                var parent = document.getElementById('downloads');
                parent.appendChild(element);
            };

            //check if file name exists in arrays
            // if true, remove from that array
            var remove = function(filename) {
                for(l = 0; l < arrs.length; l++){
                    var array = arrs[l];
                    var index = array.indexOf(filename);
                    if (index !== -1) {
                        array.splice( index, 1 );
                    };
                }
            };

            //check if filename exisits in arrays
            //add file name to array that's connected to the button
            var addToArray = function(item, type) {
                var filename = item.parentNode.previousElementSibling.innerText;
                switch(type){
                    case 'pass':
                        remove(filename);
                        pass.push(filename);
                        break;
                    case 'fail':
                        remove(filename);
                        fail.push(filename);
                        break;
                    case 'positive':
                        remove(filename);
                        positive.push(filename);
                        break;
                    case 'negative':
                        remove(filename);
                        negative.push(filename);
                        break;
                };
            };

            //style figure depending on what button was clicked
            var styleButton = function(el, type){
                var btnGroup = el.parentNode;
                var figure = el.parentNode.parentNode;
                figure.className = '';
                figure.classList.add(type);
                for (var k = 0; k < btnGroup.childNodes.length; k++) {
                    btnGroup.childNodes[k].className = "func";
                }
                el.classList.add("active");
            }


            // click event listeners for buttons
            for (var j = 0; j < btns.length; j++) {
                btns[j].addEventListener('click', function(e){
                    e.preventDefault();
                    var type = this.getAttribute('data-type');
                    addToArray(this, type);
                    styleButton(this, type);
                    return false;
                }, false);
            };

            var el = false;

            done.addEventListener('click', function(){
                var parent = document.getElementById('links');

                if (el){
                    var remove = document.getElementById('downloads');
                    remove.parentNode.removeChild(remove);
                } else {
                    el = true;
                }

                var container = document.createElement('div');
                container.id = 'downloads';

                parent.appendChild(container);

                printArrays(pass, '%s_%s_PASSED.csv');
                printArrays(fail, '%s_%s_FAILED.csv');
                printArrays(positive, '%s_%s_CHECK.csv');
                printArrays(negative, '%s_%s_TENTATIVE.csv');

                saveAll.style.display = 'inline-block';
            });

            saveAll.addEventListener('click', function(e){
                e.preventDefault();
                console.log('download all files');
                var files = document.getElementsByClassName('download');
                for( var n = 0; n < files.length; n++ ){
                    files[n].click();
                }

            });
            </script>""" % (study_name, i, study_name, i, study_name, i, study_name, i)
    return js


if __name__ == '__main__':

    import argparse

    parser = argparse.ArgumentParser("Generate orthogonal midslice views of volumes")
    parser.add_argument('-i', '--indir', dest='in_', help='Folder of images', required=True)
    parser.add_argument('-o', '--out_dir', dest='out_', help='where to put output html', required=True)
    parser.add_argument('-sn', '--study_name', dest='study_name', help='Name of the study', required=True)
    parser.add_argument('-nc', '--num_columns', dest='n_columns', help='Number of imags per row', required=False,
                        default=1,
                        type=int)
    parser.add_argument('-nf', '--num_imgs', dest='n_imgs', help='Number of imags per file', required=False,
                        default=1000,
                        type=int)

    args = parser.parse_args()

    if not Path(args.in_).is_dir():
        exit('-i should be a directory')

    run(Path(args.in_), Path(args.out_), args.n_columns, args.n_imgs,args.study_name)

