import xml.etree.ElementTree as ET
import json
import os
import codecs
import re
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(prog=os.path.basename(sys.argv[0]),
                                     formatter_class=argparse.RawDescriptionHelpFormatter,
                                     description=__doc__)
    parser.add_argument("input",  default=r"d:\onedrive\dev\ubuntu\git\DrQA\data\wikiabstract\*.xml",
                        help="XML wiki dump file")
    parser.add_argument("ouptut", default=r"d:\onedrive\dev\git\DrQA\data\wikiabstract\extract\abstract.data",
                        help="directory for extracted files (or '-' for dumping to stdout)")
    args = parser.parse_args()

    os.environ["PYTHONIOENCODING"] = 'utf-8'
    count = 0
    with codecs.open(args.input, 'r', encoding='utf-8') as xml_file:
        tree = ET.parse(xml_file)
    root = tree.getroot()
    with codecs.open(args.output, 'w', encoding='utf-8') as f:
        for doc in root.findall('doc'):

            title = doc.find('title').text

            # we proceed by elimination and we let errors go through if not identified
            if title.strip().endswith(" (disambiguation)"):
                continue
            if title.find('Wikipedia: ') >= 0:
                title = title.replace('Wikipedia: ', '').strip()
                if len(title) <= 1:
                    continue
            else:
                continue
            abstract = doc.find('abstract').text
            if abstract is None:
                continue
            abstract = abstract.strip()
            if len(abstract) < 1 or abstract[0] in ["]", "[", "{", "}"]:
                continue
            abstract = abstract.partition("|")[0].strip()
            if len(abstract) <= 20:
                continue
            if abstract.endswith(" to:"):
                continue
            abstract = re.sub("((http(s)?(\:\/\/))+(www\.)?([\w\-\.\/])*(\.[a-zA-Z]{2,3}\/?))[^\s\b\n|]*[^.,;:\?\!\@\^\$ -]", "", abstract)
            abstract = abstract.replace("  ", "").replace(",  ,", ", ").replace(", ,", ", ")
            abstract = abstract.replace("  ", "").replace("( ", "(").replace("( ", "(").replace(" )", ")").replace(" )", ")")
            abstract = abstract.replace("(;", "(").replace(";)", ")").replace("(,", "(").replace(",)", ")")
            abstract = abstract.replace("( )", "").replace("()", "")
            abstract = abstract.replace("(;", "(").replace(";)", ")").replace("(,", "(").replace(",)", ")")
            abstract = abstract.replace("(.", "(")
            abstract = abstract.replace("}}}}", "").replace("}}", "")
            abstract = abstract.replace("(surname)", "")
            if abstract.endswith("("):
                abstract = abstract.replace("(", "")
            if len(abstract) <= 20 or len(title) > len(abstract):
                continue
            text = title + ": " + abstract
            count += 1
            if count == 158:
                print("")
            f.write(json.dumps({"id": count, "text": text}, ensure_ascii=False)+"\n")
    print("done")

if __name__ == '__main__':
    main()