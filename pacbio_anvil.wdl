version 1.0

workflow Test {
  input {
    File script
    String workspace_name
    String workspace_namespace
  }

  call GET_FILEPATHS{
    input:
        script=script,
        workspace_name=workspace_name,
        workspace_namespace=workspace_namespace,
  }
}


task GET_FILEPATHS{
    input {
        File script
        String workspace_name
        String workspace_namespace
    }
    command {
        python ${script} -p ${workspace_name} -w ${workspace_namespace}
    }
    output {
        File pacbio_affected_list = "pacbio_affected_filelist.tsv"
    }
    runtime {
        docker: "us.gcr.io/broad-dsp-gcr-public/terra-jupyter-python:1.1.5"
    }
}
