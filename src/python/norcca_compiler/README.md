# NORCCA Strains Compiler

Compile a full list of currently available strains of cyanobacteria, microalgae and macroalgae found on the NORCCA website.

## Installation

Python3 and Git must first be installed.

Get a copy of the repo:

```
git clone https://github.com/nordicmicroalgae/norcca_compiler.git
cd norcca_compiler
```

Create virtual environment:

```
python -m venv venv
```

Activate virtual environment **(macOS & Linux)**:

```
source venv/bin/activate
```

Activate virtual environment **(Windows)**:

```
venv\Scripts\activate
```

Install required dependencies:

```
python -m pip install -r requirements.txt
```


## Usage

Activate virtual environment **(macOS & Linux)**:

```
cd norcca_compiler
source venv/bin/activate
```

Activate virtual environment **(Windows)**:

```
cd norcca_compiler
venv\Scripts\activate
```

Invoke the module with the output option:

```
python -m norcca_compiler --output norcca_strains.txt
```
