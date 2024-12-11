#!/usr/bin/env python

from firecloud import fiss
import pandas as pd
import io
import pprint
import json
from google.cloud import storage
import os
import argparse

print(os.environ)

parser = argparse.ArgumentParser()

parser.add_argument('-p', '--project')
parser.add_argument('-w', '--workspace')

args = parser.parse_args()

BILLING_PROJECT_ID = args.project 
WORKSPACE = args.workspace

keys = json.loads(fiss.fapi.list_entity_types(BILLING_PROJECT_ID,WORKSPACE).text).keys()

def get_table(table_name):
    return pd.read_csv(io.StringIO(fiss.fapi.get_entities_tsv(BILLING_PROJECT_ID,WORKSPACE,etype=table_name,model='flexible').text),sep='\t')

participant = get_table('participant')

exp_pb = get_table('experiment_pac_bio')

align_pb = get_table('aligned_pac_bio')

merged_table = pd.merge(exp_pb,align_pb,left_on="entity:experiment_pac_bio_id",right_on="experiment_pac_bio_id")

affected_participants = participant[participant['affected_status']=='Affected']
affected_participants

affected_table = merged_table[merged_table['experiment_sample_id'].isin(affected_participants['entity:participant_id'])]

out = affected_table[['experiment_sample_id','aligned_pac_bio_file','aligned_pac_bio_index_file']]

out.to_csv("pacbio_affected_filelist.tsv",sep="\t",index=False)
