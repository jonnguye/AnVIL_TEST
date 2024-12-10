version 1.0

workflow Test {
  File script 
  call GET_FILEPATHS {
    input :
        script=script
  }
}


task GET_FILEPATHS{
    input {
        File script
    }
    command {
        python ${script}
    }
    output {
        File pacbio_affected_list = "pacbio_affected_filelist.tsv"
    }
    runtime{
        docker: "us.gcr.io/broad-dsp-gcr-public/terra-jupyter-python:1.1.5"
    }
}
