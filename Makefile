
pip-compile:
	pip-compile --resolver=backtracking --verbose --output-file=requirements.txt requirements.in
	pip-sync requirements.txt

run:
	echo "Hi"

bash01:
	cd ./aws_bash/example_01_retrieve_available_amis;  ./get_available_amis.sh;

doc-build:
	mkdocs build

doc-serve:
	mkdocs serve --dev-addr 0.0.0.0:8031 --config-file ./mkdocs.yml --verbose #--quiet #& >/dev/null &