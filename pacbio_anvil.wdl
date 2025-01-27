version 1.0

workflow Test {
  input {
    Array[String] table_names
    String model_url
    String workspace_name
    String workspace_namespace
  }

  call export_tables{
    input:
        table_names=table_names,
        model_url=model_url,
        workspace_name=workspace_name,
        workspace_namespace=workspace_namespace,
  }

  call parse_tsv {
    input:
        table_names=table_names
  }
}

task parse_tsv {
    input {
        Array[String] table_names
    }

    command <<<
    printf ~{sep="\n" table_names} > table_names.txt
    python <<CODE
    import pandas as pd
    with open(table_names.txt) as infile:
        tables = infile.readlines()
        tables = [val.strip() for val in tables]
    for table in tables:
        df = pd.read_csv(table,sep="\t")
        df.to_json(table+".json",orient="records")
    CODE
    >>>

    output {
        Array[File] out_json = glob("*.json") 
    }
    runtime {
        docker: "quay.io/biocontainers/pandas:2.2.1"
    }
}

task export_tables {
    input {
        Array[String] table_names
        String model_url
        String workspace_name
        String workspace_namespace
    }

    command <<<
        Rscript -e "\
        model <- AnvilDataModels::json_to_dm('~{model_url}'); \
        tables <- readLines('~{write_lines(table_names)}'); \
        for (t in tables) { \
            dat <- AnVIL::avtable(t, name='~{workspace_name}', namespace='~{workspace_namespace}'); \
            readr::write_tsv(dat, paste0(t,'_noIntersect', '.tsv')); \
            ordered_cols <- intersect(names(model[[t]]), names(dat)); \
            dat <- dat[,ordered_cols]; \
            readr::write_tsv(dat, paste0(t, '.tsv')); \
        } \
        "
    >>>

    output {
        Array[File] tables = glob("*.tsv")
        File aligned_nanopore = "aligned_nanopore.tsv"
    }

    runtime {
        docker: "uwgac/anvil-util-workflows:0.5.0"
    }
}

