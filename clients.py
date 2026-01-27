import os
## Qdrant Client
from qdrant_client import QdrantClient
from dotenv import load_dotenv
load_dotenv()

VDB_API_KEY = os.getenv('VDB_API_KEY')

vdb_client = QdrantClient(
    url="http://209.51.170.42:6333/",
    api_key=VDB_API_KEY,
    verify=False,
    # prefer_grpc=True,
    # timeout=300
)
print(vdb_client.get_collections())
print(vdb_client.collection_exists("gramosynth_v3x_2"))
