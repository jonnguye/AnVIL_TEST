version 1.0

workflow Test {
  input {
    File script
    String workspace_name
    String workspace_namespace
    String workspace_bucket
  }

  call GET_FILEPATHS{
    input:
        script=script,
        workspace_name=workspace_name,
        workspace_namespace=workspace_namespace,
        workspace_bucket=workspace_bucket
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
    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/terra-jupyter-python:1.1.5"
    }
}
