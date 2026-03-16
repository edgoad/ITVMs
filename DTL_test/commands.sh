Love this question—this is where it really starts feeling “real” instead of point‑and‑click. 👍

Yes, you *can* stand this up with Azure CLI. I’ll give you a **bash-style script** you can paste into Cloud Shell (or any shell with `az` authenticated) that does the following:

*   Creates:
    *   Resource group
    *   DevTest Lab `IT385_test`
    *   VNet with:
        *   `subnet-internet`
        *   `subnet-isolated`
        *   `AzureBastionSubnet`
    *   Public IP + Bastion host
    *   3 DevTest Lab VMs:
        *   `devasc` (Ubuntu – will become your desktop/jump box)
        *   `srv1` (Ubuntu server)
        *   `srv2` (Ubuntu server)

> 🔎 **Note:** DevTest Lab VMs are not created with `az vm create`; they’re created as generic resources of type `Microsoft.DevTestLab/labs/virtualmachines` using `az resource create`. This uses the same schema as the docs for DevTest Lab labs and VMs. [\[learn.microsoft.com\]](https://learn.microsoft.com/en-us/azure/templates/microsoft.devtestlab/labs), [\[https://le...virtual...\]](https://learn.microsoft.com/en-us/azure/templates/microsoft.devtestlab/labs/virtualmachines)

You can **skip the VNet/Bastion parts** if you already created them in the portal, but having the full script is useful for future automation / other courses.

***

`az account set --subscription TechDiv`


## 0. Set variables (edit these first)

```bash
# --------- EDIT THESE VALUES ----------
RG="devtestlabs"
LOCATION="westus2"           # or whatever region you’re using
LAB_NAME="IT385_test"
VNET_NAME="it385-vnet"

# Addressing
VNET_CIDR="10.50.0.0/16"
SUBNET_INTERNET_NAME="subnet-internet"
SUBNET_INTERNET_CIDR="10.50.1.0/24"
SUBNET_ISOLATED_NAME="subnet-isolated"
SUBNET_ISOLATED_CIDR="10.50.2.0/24"
BASTION_SUBNET_CIDR="10.50.3.0/27"

# Bastion
BASTION_NAME="it385-bastion"
BASTION_PIP_NAME="${BASTION_NAME}-pip"

# VM sizing
VM_SIZE="Standard_D2s_v3"

# Ubuntu image info (Ubuntu 22.04 LTS)
UBUNTU_PUBLISHER="Canonical"
UBUNTU_OFFER="0001-com-ubuntu-server-jammy"
UBUNTU_SKU="22_04-lts"
UBUNTU_VERSION="latest"

# Lab VM names
DEVASC="devasc"
SRV1="srv1"
SRV2="srv2"

# Credentials (DO NOT hard-code in shared scripts)
ADMIN_USER="studentadmin"
ADMIN_PW="ChangeMeP@ssw0rd!"   # change at deploy time or prompt instead
# --------------------------------------
```

***

## 1. Create the resource group

```bash
az group create \
  --name "$RG" \
  --location "$LOCATION"
```

***

## 2. Create the VNet + subnets (internet, isolated, Bastion)

```bash
# VNet + first subnet
az network vnet create \
  --resource-group "$RG" \
  --name "$VNET_NAME" \
  --address-prefix "$VNET_CIDR" \
  --subnet-name "$SUBNET_INTERNET_NAME" \
  --subnet-prefix "$SUBNET_INTERNET_CIDR"

# Isolated subnet
az network vnet subnet create \
  --resource-group "$RG" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_ISOLATED_NAME" \
  --address-prefixes "$SUBNET_ISOLATED_CIDR"

# Bastion subnet (MUST be named AzureBastionSubnet)
az network vnet subnet create \
  --resource-group "$RG" \
  --vnet-name "$VNET_NAME" \
  --name "AzureBastionSubnet" \
  --address-prefixes "$BASTION_SUBNET_CIDR"
```

> Later, you’ll attach NSG and route table to `subnet-isolated` to block outbound internet. For now, this gets the structure in place.

***

## 3. Create Bastion public IP + Bastion host

Based on the Bastion quickstart ARM/CLI pattern. [\[https://le...m-template\]](https://learn.microsoft.com/en-us/azure/bastion/quickstart-host-arm-template)

```bash
# Public IP for Bastion
az network public-ip create \
  --resource-group "$RG" \
  --name "$BASTION_PIP_NAME" \
  --sku Standard \
  --location "$LOCATION" \
  --allocation-method Static

# Bastion host
az network bastion create \
  --resource-group "$RG" \
  --name "$BASTION_NAME" \
  --location "$LOCATION" \
  --public-ip-address "$BASTION_PIP_NAME" \
  --vnet-name "$VNET_NAME"
```

After this, **any VM** in that VNet can be accessed via **Connect → Bastion** in the portal (RDP/SSH over HTML5).

***

## 4. Create the DevTest Lab

DevTest Lab is a separate resource type. We use `az resource create` against `Microsoft.DevTestLab/labs`. [\[learn.microsoft.com\]](https://learn.microsoft.com/en-us/azure/templates/microsoft.devtestlab/labs)

```bash
LAB_API="2018-09-15"

az resource create \
  --resource-group "$RG" \
  --name "$LAB_NAME" \
  --resource-type "Microsoft.DevTestLab/labs" \
  --location "$LOCATION" \
  --properties '{
      "labStorageType": "Premium",
      "announcement": {
        "enabled": "Disabled",
        "markdown": ""
      }
  }' \
  --api-version "$LAB_API"
```

***

add the vnet to the lab     # This isnt right.....
```bash
LAB_VNET_NAME="it385-lab-vnet"   # this is the *lab* vnet name (can match VNET_NAME if you like)
LAB_VNET_API="2016-05-15"

az resource create \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --resource-type "Microsoft.DevTestLab/labs/virtualnetworks" \
  --name "$LAB_NAME/$LAB_VNET_NAME" \
  --api-version "$LAB_VNET_API" \
  --properties "{
    \"name\": \"$LAB_VNET_NAME\",
    \"externalProviderResourceId\": \"$VNET_ID\",
    \"allowedSubnets\": [
      {
        \"labSubnetName\": \"$SUBNET_INTERNET_NAME\",
        \"resourceId\": \"$VNET_ID/subnets/$SUBNET_INTERNET_NAME\",
        \"useInVmCreationPermission\": \"Allow\",
        \"sharedPublicIpAddressConfiguration\": {
          \"allowedPorts\": []
        }
      },
      {
        \"labSubnetName\": \"$SUBNET_ISOLATED_NAME\",
        \"resourceId\": \"$VNET_ID/subnets/$SUBNET_ISOLATED_NAME\",
        \"useInVmCreationPermission\": \"Allow\",
        \"sharedPublicIpAddressConfiguration\": {
          \"allowedPorts\": []
        }
      }
    ],
    \"subnetOverrides\": [],
    \"externalProviderResourceIdStorageState\": \"NotApplicable\"
  }"
```

## 5. Create DevTest Lab VMs: `devasc`, `srv1`, `srv2`

DevTest Lab VMs are also created via `az resource create` using resource type `Microsoft.DevTestLab/labs/virtualmachines`. [\[https://le...virtual...\]](https://learn.microsoft.com/en-us/azure/templates/microsoft.devtestlab/labs/virtualmachines), [\[https://le...d-power...\]](https://learn.microsoft.com/en-us/azure/devtest-labs/devtest-lab-use-arm-and-powershell-for-lab-resources)

> ⚠️ Important:
>
> *   Below, I’m wiring **all three** to the lab + VNet.
> *   I’m **not** explicitly selecting subnets in this first pass because subnet wiring in DevTest Labs is done via `labVirtualNetworkId` and optional subnet overrides. For a first setup, this will attach them to the VNet; you can then tweak subnet assignment in the portal or extend the JSON to include subnet overrides if needed.

First, get the VNet ID:

```bash
VNET_ID=$(az network vnet show \
  --resource-group "$RG" \
  --name "$VNET_NAME" \
  --query "id" -o tsv)
```

### 5.1 `devasc` (Ubuntu – will become your desktop/jump box)

```bash
az lab vm create \
  --lab-name "$LAB_NAME" \
  --resource-group "$RG" \
  --name "$DEVASC" \
  --image "Ubuntu Server 22.04 LTS" \
  --image-type gallery \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --admin-password "$ADMIN_PW" \
  --allow-claim false
```


# ```bash
# az resource create \
#   --resource-group "$RG" \
#   --name "$LAB_NAME/$DEVASC" \
#   --resource-type "Microsoft.DevTestLab/labs/virtualmachines" \
#   --location "$LOCATION" \
#   --api-version "$LAB_API" \
#   --properties "{
#       \"labVirtualNetworkId\": \"$VNET_ID\",
#       \"size\": \"$VM_SIZE\",
#       \"osType\": \"Linux\",
#       \"userName\": \"$ADMIN_USER\",
#       \"password\": \"$ADMIN_PW\",
#       \"galleryImageReference\": {
#         \"offer\": \"$UBUNTU_OFFER\",
#         \"publisher\": \"$UBUNTU_PUBLISHER\",
#         \"sku\": \"$UBUNTU_SKU\",
#         \"osType\": \"Linux\",
#         \"version\": \"$UBUNTU_VERSION\"
#       },
#       \"allowClaim\": false,
#       \"disallowPublicIpAddress\": true,
#       \"notes\": \"Ubuntu devasc jump box (install GUI + XRDP after deployment)\"
#   }"
# ```

After it deploys, you’ll:

*   Go to **IT385\_test → My virtual machines → devasc → Connect → Bastion (RDP)**
*   Install desktop+XRDP inside (just like we discussed earlier).

***

### 5.2 `srv1` and `srv2` (Ubuntu minimal servers)

You can reuse the same pattern for the two server VMs:


# srv1
```bash
az lab vm create \
  --lab-name "$LAB_NAME" \
  --resource-group "$RG" \
  --name "$SRV1" \
  --image "Ubuntu Server 22.04 LTS" \
  --image-type gallery \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --admin-password "$ADMIN_PW" \
  --allow-claim false
```

# srv2
```bash
az lab vm create \
  --lab-name "$LAB_NAME" \
  --resource-group "$RG" \
  --name "$SRV2" \
  --image "Ubuntu Server 22.04 LTS" \
  --image-type gallery \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --admin-password "$ADMIN_PW" \
  --allow-claim false
```

***

## 6. Next Steps After Running the CLI

Once all of that is deployed, in the Azure Portal:

1.  Go to **DevTest Labs → IT385\_test → My virtual machines**
    *   You should see: `devasc`, `srv1`, `srv2`.

2.  For **devasc**:
    *   Connect via **Bastion → RDP**.
    *   Install GUI + XRDP (if you used Server image).
    *   Optionally install your tooling (Wireshark, Nmap, Burp, etc.).
    *   Later, capture this as your **UbuntuDesktop-XRDP** custom image.

```bash
sudo apt update
sudo apt install ubuntu-desktop -y   # if you deployed the Server SKU
sudo apt install xrdp -y
sudo systemctl enable xrdp
sudo systemctl restart xrdp
sudo ufw allow 3389
```

3.  For **srv1 / srv2**:
    *   Verify they’re reachable from `devasc` via SSH.
    *   Later, you can customize them and capture as a minimal “victim” image.

4.  Add NSG + route table to `subnet-isolated` to block internet from `srv1`/`srv2` when you’re ready to lock it down.

***

## Want a refinement?

The next refinement I’d suggest is:

*   a small **bash function** or script that:
    *   Creates per‑student copies of this environment (or at least of `devasc` + `srv1`/`srv2`) in the same Lab,
    *   Or generating a **custom image** from `devasc` after you finish XRDP setup and adjusting the CLI so future runs use that image instead of gallery Ubuntu.

If you tell me whether you want **one shared environment per class** or **one environment per student**, I can tailor the next set of CLI snippets to match your classroom model.
