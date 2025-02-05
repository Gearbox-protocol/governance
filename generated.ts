//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// AddressProvider
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const addressProviderAbi = [
  {
    type: 'constructor',
    inputs: [{ name: '_owner', internalType: 'address', type: 'address' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: '', internalType: 'string', type: 'string' },
      { name: '', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'addresses',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'contractType',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'key', internalType: 'string', type: 'string' },
      { name: '_version', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'getAddressOrRevert',
    outputs: [{ name: 'result', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'key', internalType: 'bytes32', type: 'bytes32' },
      { name: '_version', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'getAddressOrRevert',
    outputs: [{ name: 'result', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getAllSavedContracts',
    outputs: [
      {
        name: '',
        internalType: 'struct ContractValue[]',
        type: 'tuple[]',
        components: [
          { name: 'key', internalType: 'string', type: 'string' },
          { name: 'value', internalType: 'address', type: 'address' },
          { name: 'version', internalType: 'uint256', type: 'uint256' },
        ],
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'key', internalType: 'string', type: 'string' },
      { name: 'majorVersion', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'getLatestMinorVersion',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'key', internalType: 'string', type: 'string' },
      { name: 'minorVersion', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'getLatestPatchVersion',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'key', internalType: 'string', type: 'string' }],
    name: 'getLatestVersion',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: '', internalType: 'string', type: 'string' },
      { name: '', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'latestMinorVersions',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: '', internalType: 'string', type: 'string' },
      { name: '', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'latestPatchVersions',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: '', internalType: 'string', type: 'string' }],
    name: 'latestVersions',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'owner',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'key', internalType: 'string', type: 'string' },
      { name: 'value', internalType: 'address', type: 'address' },
      { name: 'saveVersion', internalType: 'bool', type: 'bool' },
    ],
    name: 'setAddress',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'addr', internalType: 'address', type: 'address' },
      { name: 'saveVersion', internalType: 'bool', type: 'bool' },
    ],
    name: 'setAddress',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'key', internalType: 'bytes32', type: 'bytes32' },
      { name: 'value', internalType: 'address', type: 'address' },
      { name: 'saveVersion', internalType: 'bool', type: 'bool' },
    ],
    name: 'setAddress',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'version',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'key', internalType: 'string', type: 'string', indexed: true },
      {
        name: 'version',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
      {
        name: 'value',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'SetAddress',
  },
  { type: 'error', inputs: [], name: 'AddressNotFoundException' },
  {
    type: 'error',
    inputs: [{ name: 'caller', internalType: 'address', type: 'address' }],
    name: 'CallerIsNotOwnerException',
  },
  { type: 'error', inputs: [], name: 'VersionNotFoundException' },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// DefaultLossPolicy
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const defaultLossPolicyAbi = [
  {
    type: 'constructor',
    inputs: [{ name: 'acl_', internalType: 'address', type: 'address' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'acl',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'contractType',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'disable',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'enable',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'enabled',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: '', internalType: 'address', type: 'address' },
      { name: '', internalType: 'address', type: 'address' },
      { name: '', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'isLiquidatable',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'version',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'error',
    inputs: [{ name: '', internalType: 'address', type: 'address' }],
    name: 'AddressIsNotContractException',
  },
  { type: 'error', inputs: [], name: 'CallerNotConfiguratorException' },
  { type: 'error', inputs: [], name: 'ZeroAddressException' },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// IAliasLossPolicy
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iAliasLossPolicyAbi = [
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'priceFeed', internalType: 'address', type: 'address' },
    ],
    name: 'setAlias',
    outputs: [],
    stateMutability: 'nonpayable',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// IBytecodeRepository
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iBytecodeRepositoryAbi = [
  {
    type: 'function',
    inputs: [],
    name: 'BYTECODE_TYPEHASH',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'auditor', internalType: 'address', type: 'address' },
      { name: 'name', internalType: 'string', type: 'string' },
    ],
    name: 'addAuditor',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'domain', internalType: 'bytes32', type: 'bytes32' }],
    name: 'addPublicDomain',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'allowSystemContract',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'allowedSystemContracts',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'contractType', internalType: 'bytes32', type: 'bytes32' },
      { name: 'version', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'approvedBytecodeHash',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'auditor', internalType: 'address', type: 'address' }],
    name: 'auditorName',
    outputs: [{ name: '', internalType: 'string', type: 'string' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
      { name: 'index', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'auditorSignaturesByHash',
    outputs: [
      {
        name: '',
        internalType: 'struct AuditorSignature',
        type: 'tuple',
        components: [
          { name: 'reportUrl', internalType: 'string', type: 'string' },
          { name: 'auditor', internalType: 'address', type: 'address' },
          { name: 'signature', internalType: 'bytes', type: 'bytes' },
        ],
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'auditorSignaturesByHash',
    outputs: [
      {
        name: '',
        internalType: 'struct AuditorSignature[]',
        type: 'tuple[]',
        components: [
          { name: 'reportUrl', internalType: 'string', type: 'string' },
          { name: 'auditor', internalType: 'address', type: 'address' },
          { name: 'signature', internalType: 'bytes', type: 'bytes' },
        ],
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'hash', internalType: 'bytes32', type: 'bytes32' }],
    name: 'bytecodeByHash',
    outputs: [
      {
        name: '',
        internalType: 'struct Bytecode',
        type: 'tuple',
        components: [
          { name: 'contractType', internalType: 'bytes32', type: 'bytes32' },
          { name: 'version', internalType: 'uint256', type: 'uint256' },
          { name: 'initCode', internalType: 'bytes', type: 'bytes' },
          { name: 'author', internalType: 'address', type: 'address' },
          { name: 'source', internalType: 'string', type: 'string' },
          { name: 'authorSignature', internalType: 'bytes', type: 'bytes' },
        ],
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'type_', internalType: 'bytes32', type: 'bytes32' },
      { name: 'version_', internalType: 'uint256', type: 'uint256' },
      { name: 'constructorParams', internalType: 'bytes', type: 'bytes' },
      { name: 'salt', internalType: 'bytes32', type: 'bytes32' },
      { name: 'deployer', internalType: 'address', type: 'address' },
    ],
    name: 'computeAddress',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      {
        name: 'bytecode',
        internalType: 'struct Bytecode',
        type: 'tuple',
        components: [
          { name: 'contractType', internalType: 'bytes32', type: 'bytes32' },
          { name: 'version', internalType: 'uint256', type: 'uint256' },
          { name: 'initCode', internalType: 'bytes', type: 'bytes' },
          { name: 'author', internalType: 'address', type: 'address' },
          { name: 'source', internalType: 'string', type: 'string' },
          { name: 'authorSignature', internalType: 'bytes', type: 'bytes' },
        ],
      },
    ],
    name: 'computeBytecodeHash',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'pure',
  },
  {
    type: 'function',
    inputs: [],
    name: 'contractType',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'contractType', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'contractTypeOwner',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'type_', internalType: 'bytes32', type: 'bytes32' },
      { name: 'version_', internalType: 'uint256', type: 'uint256' },
      { name: 'constructorParams', internalType: 'bytes', type: 'bytes' },
      { name: 'salt', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'deploy',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'contractAddress', internalType: 'address', type: 'address' },
    ],
    name: 'deployedContracts',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'initCodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'forbidInitCode',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'initCodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'forbiddenInitCode',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getAuditors',
    outputs: [{ name: '', internalType: 'address[]', type: 'address[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'type_', internalType: 'bytes32', type: 'bytes32' },
      { name: 'majorVersion', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'getLatestMinorVersion',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'type_', internalType: 'bytes32', type: 'bytes32' },
      { name: 'minorVersion', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'getLatestPatchVersion',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'type_', internalType: 'bytes32', type: 'bytes32' }],
    name: 'getLatestVersion',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'token', internalType: 'address', type: 'address' }],
    name: 'getTokenSpecificPostfix',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'isAuditBytecode',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'auditor', internalType: 'address', type: 'address' }],
    name: 'isAuditor',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'isBytecodeUploaded',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'contractType', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'isInPublicDomain',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'domain', internalType: 'bytes32', type: 'bytes32' }],
    name: 'isPublicDomain',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'listPublicDomains',
    outputs: [{ name: '', internalType: 'bytes32[]', type: 'bytes32[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'owner',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'auditor', internalType: 'address', type: 'address' }],
    name: 'removeAuditor',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'contractType', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'removeContractTypeOwner',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'domain', internalType: 'bytes32', type: 'bytes32' }],
    name: 'removePublicDomain',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'initCode', internalType: 'bytes', type: 'bytes' }],
    name: 'revertIfInitCodeForbidden',
    outputs: [],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'contractType', internalType: 'bytes32', type: 'bytes32' },
      { name: 'version', internalType: 'uint256', type: 'uint256' },
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'revokeApproval',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'postfix', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'setTokenSpecificPostfix',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
      { name: 'reportUrl', internalType: 'string', type: 'string' },
      { name: 'signature', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'signBytecodeHash',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      {
        name: 'bytecode',
        internalType: 'struct Bytecode',
        type: 'tuple',
        components: [
          { name: 'contractType', internalType: 'bytes32', type: 'bytes32' },
          { name: 'version', internalType: 'uint256', type: 'uint256' },
          { name: 'initCode', internalType: 'bytes', type: 'bytes' },
          { name: 'author', internalType: 'address', type: 'address' },
          { name: 'source', internalType: 'string', type: 'string' },
          { name: 'authorSignature', internalType: 'bytes', type: 'bytes' },
        ],
      },
    ],
    name: 'uploadBytecode',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'version',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'auditor',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      { name: 'name', internalType: 'string', type: 'string', indexed: false },
    ],
    name: 'AddAuditor',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'domain',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
    ],
    name: 'AddPublicDomain',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'bytecodeHash',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
      {
        name: 'contractType',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
      {
        name: 'version',
        internalType: 'uint256',
        type: 'uint256',
        indexed: false,
      },
    ],
    name: 'ApproveContract',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'bytecodeHash',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
      {
        name: 'auditor',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'reportUrl',
        internalType: 'string',
        type: 'string',
        indexed: false,
      },
      {
        name: 'signature',
        internalType: 'bytes',
        type: 'bytes',
        indexed: false,
      },
    ],
    name: 'AuditBytecode',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'addr', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'bytecodeHash',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
      {
        name: 'contractType',
        internalType: 'string',
        type: 'string',
        indexed: false,
      },
      {
        name: 'version',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
    ],
    name: 'DeployContract',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'bytecodeHash',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
    ],
    name: 'ForbidBytecode',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'auditor',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'RemoveAuditor',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'contractType',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
    ],
    name: 'RemoveContractTypeOwner',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'domain',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
    ],
    name: 'RemovePublicDomain',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'bytecodeHash',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
      {
        name: 'contractType',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
      {
        name: 'version',
        internalType: 'uint256',
        type: 'uint256',
        indexed: false,
      },
    ],
    name: 'RevokeApproval',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'postfix',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
    ],
    name: 'SetTokenSpecificPostfix',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'bytecodeHash',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
      {
        name: 'contractType',
        internalType: 'string',
        type: 'string',
        indexed: false,
      },
      {
        name: 'version',
        internalType: 'uint256',
        type: 'uint256',
        indexed: true,
      },
      {
        name: 'author',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'source',
        internalType: 'string',
        type: 'string',
        indexed: false,
      },
    ],
    name: 'UploadBytecode',
  },
  { type: 'error', inputs: [], name: 'AuditorAlreadyAddedException' },
  { type: 'error', inputs: [], name: 'AuditorAlreadySignedException' },
  { type: 'error', inputs: [], name: 'AuditorNotFoundException' },
  {
    type: 'error',
    inputs: [{ name: '', internalType: 'address', type: 'address' }],
    name: 'BytecodeAlreadyExistsAtAddressException',
  },
  { type: 'error', inputs: [], name: 'BytecodeAlreadyExistsException' },
  {
    type: 'error',
    inputs: [
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'BytecodeForbiddenException',
  },
  {
    type: 'error',
    inputs: [
      { name: 'contractType', internalType: 'bytes32', type: 'bytes32' },
      { name: 'version', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'BytecodeIsNotApprovedException',
  },
  { type: 'error', inputs: [], name: 'BytecodeIsNotAuditedException' },
  {
    type: 'error',
    inputs: [
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'BytecodeIsNotUploadedException',
  },
  {
    type: 'error',
    inputs: [{ name: 'caller', internalType: 'address', type: 'address' }],
    name: 'CallerIsNotOwnerException',
  },
  { type: 'error', inputs: [], name: 'ContractIsNotAuditedException' },
  {
    type: 'error',
    inputs: [],
    name: 'ContractTypeVersionAlreadyExistsException',
  },
  { type: 'error', inputs: [], name: 'EmptyBytecodeException' },
  {
    type: 'error',
    inputs: [
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'IncorrectBytecodeException',
  },
  { type: 'error', inputs: [], name: 'InvalidAuthorSignatureException' },
  { type: 'error', inputs: [], name: 'NoValidAuditorPermissionsAException' },
  { type: 'error', inputs: [], name: 'NoValidAuditorSignatureException' },
  {
    type: 'error',
    inputs: [
      { name: 'bytecodeHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'NotAllowedSystemContractException',
  },
  { type: 'error', inputs: [], name: 'NotDeployerException' },
  { type: 'error', inputs: [], name: 'NotDomainOwnerException' },
  { type: 'error', inputs: [], name: 'OnlyAuthorCanSyncException' },
  {
    type: 'error',
    inputs: [{ name: 'signer', internalType: 'address', type: 'address' }],
    name: 'SignerIsNotAuditorException',
  },
  {
    type: 'error',
    inputs: [{ name: '', internalType: 'string', type: 'string' }],
    name: 'TooLongContractTypeException',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ICreditConfigureActions
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iCreditConfigureActionsAbi = [
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'liquidationThreshold', internalType: 'uint16', type: 'uint16' },
    ],
    name: 'addCollateralToken',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      {
        name: 'params',
        internalType: 'struct DeployParams',
        type: 'tuple',
        components: [
          { name: 'postfix', internalType: 'bytes32', type: 'bytes32' },
          { name: 'salt', internalType: 'bytes32', type: 'bytes32' },
          { name: 'constructorParams', internalType: 'bytes', type: 'bytes' },
        ],
      },
    ],
    name: 'allowAdapter',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'token', internalType: 'address', type: 'address' }],
    name: 'allowToken',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'targetContract', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'configureAdapterFor',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'adapter', internalType: 'address', type: 'address' }],
    name: 'forbidAdapter',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'token', internalType: 'address', type: 'address' }],
    name: 'forbidToken',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'pause',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      {
        name: 'liquidationThresholdFinal',
        internalType: 'uint16',
        type: 'uint16',
      },
      { name: 'rampStart', internalType: 'uint40', type: 'uint40' },
      { name: 'rampDuration', internalType: 'uint24', type: 'uint24' },
    ],
    name: 'rampLiquidationThreshold',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'newExpirationDate', internalType: 'uint40', type: 'uint40' },
    ],
    name: 'setExpirationDate',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'feeLiquidation', internalType: 'uint16', type: 'uint16' },
      { name: 'liquidationPremium', internalType: 'uint16', type: 'uint16' },
      { name: 'feeLiquidationExpired', internalType: 'uint16', type: 'uint16' },
      {
        name: 'liquidationPremiumExpired',
        internalType: 'uint16',
        type: 'uint16',
      },
    ],
    name: 'setFees',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      {
        name: 'newMaxDebtLimitPerBlockMultiplier',
        internalType: 'uint8',
        type: 'uint8',
      },
    ],
    name: 'setMaxDebtPerBlockMultiplier',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'unpause',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'upgradeCreditConfigurator',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      {
        name: 'params',
        internalType: 'struct CreditFacadeParams',
        type: 'tuple',
        components: [
          { name: 'degenNFT', internalType: 'address', type: 'address' },
          { name: 'expirable', internalType: 'bool', type: 'bool' },
          { name: 'migrateBotList', internalType: 'bool', type: 'bool' },
        ],
      },
    ],
    name: 'upgradeCreditFacade',
    outputs: [],
    stateMutability: 'nonpayable',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ICrossChainMultisig
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iCrossChainMultisigAbi = [
  {
    type: 'function',
    inputs: [{ name: 'signer', internalType: 'address', type: 'address' }],
    name: 'addSigner',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'confirmationThreshold',
    outputs: [{ name: '', internalType: 'uint8', type: 'uint8' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'contractType',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'domainSeparatorV4',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      {
        name: 'proposal',
        internalType: 'struct SignedProposal',
        type: 'tuple',
        components: [
          { name: 'name', internalType: 'string', type: 'string' },
          { name: 'prevHash', internalType: 'bytes32', type: 'bytes32' },
          {
            name: 'calls',
            internalType: 'struct CrossChainCall[]',
            type: 'tuple[]',
            components: [
              { name: 'chainId', internalType: 'uint256', type: 'uint256' },
              { name: 'target', internalType: 'address', type: 'address' },
              { name: 'callData', internalType: 'bytes', type: 'bytes' },
            ],
          },
          { name: 'signatures', internalType: 'bytes[]', type: 'bytes[]' },
        ],
      },
    ],
    name: 'executeProposal',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getCurrentProposalHashes',
    outputs: [{ name: '', internalType: 'bytes32[]', type: 'bytes32[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getExecutedProposalHashes',
    outputs: [{ name: '', internalType: 'bytes32[]', type: 'bytes32[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'proposalHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'getProposal',
    outputs: [
      {
        name: '',
        internalType: 'struct SignedProposal',
        type: 'tuple',
        components: [
          { name: 'name', internalType: 'string', type: 'string' },
          { name: 'prevHash', internalType: 'bytes32', type: 'bytes32' },
          {
            name: 'calls',
            internalType: 'struct CrossChainCall[]',
            type: 'tuple[]',
            components: [
              { name: 'chainId', internalType: 'uint256', type: 'uint256' },
              { name: 'target', internalType: 'address', type: 'address' },
              { name: 'callData', internalType: 'bytes', type: 'bytes' },
            ],
          },
          { name: 'signatures', internalType: 'bytes[]', type: 'bytes[]' },
        ],
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getSigners',
    outputs: [{ name: '', internalType: 'address[]', type: 'address[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'name', internalType: 'string', type: 'string' },
      {
        name: 'calls',
        internalType: 'struct CrossChainCall[]',
        type: 'tuple[]',
        components: [
          { name: 'chainId', internalType: 'uint256', type: 'uint256' },
          { name: 'target', internalType: 'address', type: 'address' },
          { name: 'callData', internalType: 'bytes', type: 'bytes' },
        ],
      },
      { name: 'prevHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'hashProposal',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'account', internalType: 'address', type: 'address' }],
    name: 'isSigner',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'lastProposalHash',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'signer', internalType: 'address', type: 'address' }],
    name: 'removeSigner',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'newThreshold', internalType: 'uint8', type: 'uint8' }],
    name: 'setConfirmationThreshold',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'proposalHash', internalType: 'bytes32', type: 'bytes32' },
      { name: 'signature', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'signProposal',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'name', internalType: 'string', type: 'string' },
      {
        name: 'calls',
        internalType: 'struct CrossChainCall[]',
        type: 'tuple[]',
        components: [
          { name: 'chainId', internalType: 'uint256', type: 'uint256' },
          { name: 'target', internalType: 'address', type: 'address' },
          { name: 'callData', internalType: 'bytes', type: 'bytes' },
        ],
      },
      { name: 'prevHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'submitProposal',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'version',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'signer',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'AddSigner',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'proposalHash',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
    ],
    name: 'ExecuteProposal',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'signer',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'RemoveSigner',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'newconfirmationThreshold',
        internalType: 'uint8',
        type: 'uint8',
        indexed: false,
      },
    ],
    name: 'SetConfirmationThreshold',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'proposalHash',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
      {
        name: 'signer',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'SignProposal',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'proposalHash',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
    ],
    name: 'SubmitProposal',
  },
  { type: 'error', inputs: [], name: 'AlreadySignedException' },
  { type: 'error', inputs: [], name: 'CantBeExecutedOnCurrentChainException' },
  {
    type: 'error',
    inputs: [],
    name: 'InconsistentSelfCallOnOtherChainException',
  },
  {
    type: 'error',
    inputs: [],
    name: 'InvalidConfirmationThresholdValueException',
  },
  { type: 'error', inputs: [], name: 'InvalidPrevHashException' },
  { type: 'error', inputs: [], name: 'InvalidconfirmationThresholdException' },
  { type: 'error', inputs: [], name: 'NoCallsInProposalException' },
  { type: 'error', inputs: [], name: 'NotEnoughSignaturesException' },
  { type: 'error', inputs: [], name: 'OnlySelfException' },
  { type: 'error', inputs: [], name: 'ProposalDoesNotExistException' },
  { type: 'error', inputs: [], name: 'SignerAlreadyExistsException' },
  { type: 'error', inputs: [], name: 'SignerDoesNotExistException' },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// IGaugeV3
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iGaugeV3Abi = [
  {
    type: 'function',
    inputs: [],
    name: 'acl',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'minRate', internalType: 'uint16', type: 'uint16' },
      { name: 'maxRate', internalType: 'uint16', type: 'uint16' },
    ],
    name: 'addQuotaToken',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'token', internalType: 'address', type: 'address' }],
    name: 'addToken',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'maxRate', internalType: 'uint16', type: 'uint16' },
    ],
    name: 'changeQuotaMaxRate',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'minRate', internalType: 'uint16', type: 'uint16' },
    ],
    name: 'changeQuotaMinRate',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'contractType',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'epochFrozen',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'epochLastUpdate',
    outputs: [{ name: '', internalType: 'uint16', type: 'uint16' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'tokens', internalType: 'address[]', type: 'address[]' }],
    name: 'getRates',
    outputs: [{ name: '', internalType: 'uint16[]', type: 'uint16[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'token', internalType: 'address', type: 'address' }],
    name: 'isTokenAdded',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'pool',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'token', internalType: 'address', type: 'address' }],
    name: 'quotaRateParams',
    outputs: [
      { name: 'minRate', internalType: 'uint16', type: 'uint16' },
      { name: 'maxRate', internalType: 'uint16', type: 'uint16' },
      { name: 'totalVotesLpSide', internalType: 'uint96', type: 'uint96' },
      { name: 'totalVotesCaSide', internalType: 'uint96', type: 'uint96' },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'status', internalType: 'bool', type: 'bool' }],
    name: 'setFrozenEpoch',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'user', internalType: 'address', type: 'address' },
      { name: 'votes', internalType: 'uint96', type: 'uint96' },
      { name: 'extraData', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'unvote',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'updateEpoch',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'user', internalType: 'address', type: 'address' },
      { name: 'token', internalType: 'address', type: 'address' },
    ],
    name: 'userTokenVotes',
    outputs: [
      { name: 'votesLpSide', internalType: 'uint96', type: 'uint96' },
      { name: 'votesCaSide', internalType: 'uint96', type: 'uint96' },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'version',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'user', internalType: 'address', type: 'address' },
      { name: 'votes', internalType: 'uint96', type: 'uint96' },
      { name: 'extraData', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'vote',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'voter',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'minRate',
        internalType: 'uint16',
        type: 'uint16',
        indexed: false,
      },
      {
        name: 'maxRate',
        internalType: 'uint16',
        type: 'uint16',
        indexed: false,
      },
    ],
    name: 'AddQuotaToken',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'status', internalType: 'bool', type: 'bool', indexed: false },
    ],
    name: 'SetFrozenEpoch',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'minRate',
        internalType: 'uint16',
        type: 'uint16',
        indexed: false,
      },
      {
        name: 'maxRate',
        internalType: 'uint16',
        type: 'uint16',
        indexed: false,
      },
    ],
    name: 'SetQuotaTokenParams',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'user', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      { name: 'votes', internalType: 'uint96', type: 'uint96', indexed: false },
      { name: 'lpSide', internalType: 'bool', type: 'bool', indexed: false },
    ],
    name: 'Unvote',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'epochNow',
        internalType: 'uint16',
        type: 'uint16',
        indexed: false,
      },
    ],
    name: 'UpdateEpoch',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'user', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      { name: 'votes', internalType: 'uint96', type: 'uint96', indexed: false },
      { name: 'lpSide', internalType: 'bool', type: 'bool', indexed: false },
    ],
    name: 'Vote',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// IGaugeV3Events
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iGaugeV3EventsAbi = [
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'minRate',
        internalType: 'uint16',
        type: 'uint16',
        indexed: false,
      },
      {
        name: 'maxRate',
        internalType: 'uint16',
        type: 'uint16',
        indexed: false,
      },
    ],
    name: 'AddQuotaToken',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'status', internalType: 'bool', type: 'bool', indexed: false },
    ],
    name: 'SetFrozenEpoch',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'minRate',
        internalType: 'uint16',
        type: 'uint16',
        indexed: false,
      },
      {
        name: 'maxRate',
        internalType: 'uint16',
        type: 'uint16',
        indexed: false,
      },
    ],
    name: 'SetQuotaTokenParams',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'user', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      { name: 'votes', internalType: 'uint96', type: 'uint96', indexed: false },
      { name: 'lpSide', internalType: 'bool', type: 'bool', indexed: false },
    ],
    name: 'Unvote',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'epochNow',
        internalType: 'uint16',
        type: 'uint16',
        indexed: false,
      },
    ],
    name: 'UpdateEpoch',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'user', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      { name: 'votes', internalType: 'uint96', type: 'uint96', indexed: false },
      { name: 'lpSide', internalType: 'bool', type: 'bool', indexed: false },
    ],
    name: 'Vote',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// IInstanceManager
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iInstanceManagerAbi = [
  {
    type: 'function',
    inputs: [
      { name: 'instanceOwner', internalType: 'address', type: 'address' },
      { name: 'treasury', internalType: 'address', type: 'address' },
      { name: 'weth', internalType: 'address', type: 'address' },
      { name: 'gear', internalType: 'address', type: 'address' },
    ],
    name: 'activate',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'addressProvider',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'bytecodeRepository',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'target', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'configureGlobal',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'target', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'configureLocal',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'target', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'configureTreasury',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'contractType',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'crossChainGovernanceProxy',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'contractType', internalType: 'bytes32', type: 'bytes32' },
      { name: 'version', internalType: 'uint256', type: 'uint256' },
      { name: 'saveVersion', internalType: 'bool', type: 'bool' },
    ],
    name: 'deploySystemContract',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'instanceManagerProxy',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'isActivated',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'owner',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'key', internalType: 'string', type: 'string' },
      { name: 'addr', internalType: 'address', type: 'address' },
      { name: 'saveVersion', internalType: 'bool', type: 'bool' },
    ],
    name: 'setGlobalAddress',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'key', internalType: 'string', type: 'string' },
      { name: 'addr', internalType: 'address', type: 'address' },
      { name: 'saveVersion', internalType: 'bool', type: 'bool' },
    ],
    name: 'setLegacyAddress',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'key', internalType: 'string', type: 'string' },
      { name: 'addr', internalType: 'address', type: 'address' },
      { name: 'saveVersion', internalType: 'bool', type: 'bool' },
    ],
    name: 'setLocalAddress',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'treasuryProxy',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'version',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// IMarketConfigurator
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iMarketConfiguratorAbi = [
  {
    type: 'function',
    inputs: [],
    name: 'acl',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'peripheryContract', internalType: 'address', type: 'address' },
    ],
    name: 'addPeripheryContract',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'priceFeed', internalType: 'address', type: 'address' },
    ],
    name: 'addToken',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'addressProvider',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'admin',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'factory', internalType: 'address', type: 'address' },
      { name: 'suite', internalType: 'address', type: 'address' },
      { name: 'target', internalType: 'address', type: 'address' },
    ],
    name: 'authorizeFactory',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'bytecodeRepository',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'creditManager', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'configureCreditSuite',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'configureInterestRateModel',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'configureLossPolicy',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'configurePool',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'configurePriceOracle',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'configureRateKeeper',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'contractType',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'contractsRegister',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'minorVersion', internalType: 'uint256', type: 'uint256' },
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'encdodedParams', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'createCreditSuite',
    outputs: [
      { name: 'creditManager', internalType: 'address', type: 'address' },
    ],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'minorVersion', internalType: 'uint256', type: 'uint256' },
      { name: 'underlying', internalType: 'address', type: 'address' },
      { name: 'name', internalType: 'string', type: 'string' },
      { name: 'symbol', internalType: 'string', type: 'string' },
      {
        name: 'interestRateModelParams',
        internalType: 'struct DeployParams',
        type: 'tuple',
        components: [
          { name: 'postfix', internalType: 'bytes32', type: 'bytes32' },
          { name: 'salt', internalType: 'bytes32', type: 'bytes32' },
          { name: 'constructorParams', internalType: 'bytes', type: 'bytes' },
        ],
      },
      {
        name: 'rateKeeperParams',
        internalType: 'struct DeployParams',
        type: 'tuple',
        components: [
          { name: 'postfix', internalType: 'bytes32', type: 'bytes32' },
          { name: 'salt', internalType: 'bytes32', type: 'bytes32' },
          { name: 'constructorParams', internalType: 'bytes', type: 'bytes' },
        ],
      },
      {
        name: 'lossPolicyParams',
        internalType: 'struct DeployParams',
        type: 'tuple',
        components: [
          { name: 'postfix', internalType: 'bytes32', type: 'bytes32' },
          { name: 'salt', internalType: 'bytes32', type: 'bytes32' },
          { name: 'constructorParams', internalType: 'bytes', type: 'bytes' },
        ],
      },
      { name: 'underlyingPriceFeed', internalType: 'address', type: 'address' },
    ],
    name: 'createMarket',
    outputs: [{ name: 'pool', internalType: 'address', type: 'address' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'curatorName',
    outputs: [{ name: '', internalType: 'string', type: 'string' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'emergencyAdmin',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'creditManager', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'emergencyConfigureCreditSuite',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'emergencyConfigureInterestRateModel',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'emergencyConfigureLossPolicy',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'emergencyConfigurePool',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'emergencyConfigurePriceOracle',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'data', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'emergencyConfigureRateKeeper',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'role', internalType: 'bytes32', type: 'bytes32' },
      { name: 'account', internalType: 'address', type: 'address' },
    ],
    name: 'emergencyRevokeRole',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'target', internalType: 'address', type: 'address' }],
    name: 'getAuthorizedFactory',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'creditManager', internalType: 'address', type: 'address' },
    ],
    name: 'getCreditFactory',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'factory', internalType: 'address', type: 'address' },
      { name: 'suite', internalType: 'address', type: 'address' },
    ],
    name: 'getFactoryTargets',
    outputs: [{ name: '', internalType: 'address[]', type: 'address[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'pool', internalType: 'address', type: 'address' }],
    name: 'getMarketFactories',
    outputs: [
      {
        name: '',
        internalType: 'struct MarketFactories',
        type: 'tuple',
        components: [
          { name: 'poolFactory', internalType: 'address', type: 'address' },
          {
            name: 'priceOracleFactory',
            internalType: 'address',
            type: 'address',
          },
          {
            name: 'interestRateModelFactory',
            internalType: 'address',
            type: 'address',
          },
          {
            name: 'rateKeeperFactory',
            internalType: 'address',
            type: 'address',
          },
          {
            name: 'lossPolicyFactory',
            internalType: 'address',
            type: 'address',
          },
        ],
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'domain', internalType: 'bytes32', type: 'bytes32' }],
    name: 'getPeripheryContracts',
    outputs: [{ name: '', internalType: 'address[]', type: 'address[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'role', internalType: 'bytes32', type: 'bytes32' },
      { name: 'account', internalType: 'address', type: 'address' },
    ],
    name: 'grantRole',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'domain', internalType: 'bytes32', type: 'bytes32' },
      { name: 'peripheryContract', internalType: 'address', type: 'address' },
    ],
    name: 'isPeripheryContract',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'marketMinorVersion', internalType: 'uint256', type: 'uint256' },
      {
        name: 'creditSuiteMinorVersion',
        internalType: 'uint256',
        type: 'uint256',
      },
      { name: 'underlying', internalType: 'address', type: 'address' },
      { name: 'name', internalType: 'string', type: 'string' },
      { name: 'symbol', internalType: 'string', type: 'string' },
      { name: 'encodedParams', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'previewCreateCreditSuite',
    outputs: [
      { name: 'creditManager', internalType: 'address', type: 'address' },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'minorVersion', internalType: 'uint256', type: 'uint256' },
      { name: 'pool', internalType: 'address', type: 'address' },
      { name: 'encodedParams', internalType: 'bytes', type: 'bytes' },
    ],
    name: 'previewCreateCreditSuite',
    outputs: [
      { name: 'creditManager', internalType: 'address', type: 'address' },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'minorVersion', internalType: 'uint256', type: 'uint256' },
      { name: 'underlying', internalType: 'address', type: 'address' },
      { name: 'name', internalType: 'string', type: 'string' },
      { name: 'symbol', internalType: 'string', type: 'string' },
    ],
    name: 'previewCreateMarket',
    outputs: [{ name: 'pool', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'peripheryContract', internalType: 'address', type: 'address' },
    ],
    name: 'removePeripheryContract',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'role', internalType: 'bytes32', type: 'bytes32' },
      { name: 'account', internalType: 'address', type: 'address' },
    ],
    name: 'revokeRole',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'newEmergencyAdmin', internalType: 'address', type: 'address' },
    ],
    name: 'setEmergencyAdmin',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'creditManager', internalType: 'address', type: 'address' },
    ],
    name: 'shutdownCreditSuite',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'pool', internalType: 'address', type: 'address' }],
    name: 'shutdownMarket',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'treasury',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'factory', internalType: 'address', type: 'address' },
      { name: 'suite', internalType: 'address', type: 'address' },
      { name: 'target', internalType: 'address', type: 'address' },
    ],
    name: 'unauthorizeFactory',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      {
        name: 'params',
        internalType: 'struct DeployParams',
        type: 'tuple',
        components: [
          { name: 'postfix', internalType: 'bytes32', type: 'bytes32' },
          { name: 'salt', internalType: 'bytes32', type: 'bytes32' },
          { name: 'constructorParams', internalType: 'bytes', type: 'bytes' },
        ],
      },
    ],
    name: 'updateInterestRateModel',
    outputs: [{ name: 'irm', internalType: 'address', type: 'address' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      {
        name: 'params',
        internalType: 'struct DeployParams',
        type: 'tuple',
        components: [
          { name: 'postfix', internalType: 'bytes32', type: 'bytes32' },
          { name: 'salt', internalType: 'bytes32', type: 'bytes32' },
          { name: 'constructorParams', internalType: 'bytes', type: 'bytes' },
        ],
      },
    ],
    name: 'updateLossPolicy',
    outputs: [{ name: 'lossPolicy', internalType: 'address', type: 'address' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'pool', internalType: 'address', type: 'address' }],
    name: 'updatePriceOracle',
    outputs: [
      { name: 'priceOracle', internalType: 'address', type: 'address' },
    ],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address' },
      {
        name: 'params',
        internalType: 'struct DeployParams',
        type: 'tuple',
        components: [
          { name: 'postfix', internalType: 'bytes32', type: 'bytes32' },
          { name: 'salt', internalType: 'bytes32', type: 'bytes32' },
          { name: 'constructorParams', internalType: 'bytes', type: 'bytes' },
        ],
      },
    ],
    name: 'updateRateKeeper',
    outputs: [{ name: 'rateKeeper', internalType: 'address', type: 'address' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'creditManager', internalType: 'address', type: 'address' },
    ],
    name: 'upgradeCreditFactory',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'pool', internalType: 'address', type: 'address' }],
    name: 'upgradeInterestRateModelFactory',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'pool', internalType: 'address', type: 'address' }],
    name: 'upgradeLossPolicyFactory',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'pool', internalType: 'address', type: 'address' }],
    name: 'upgradePoolFactory',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'pool', internalType: 'address', type: 'address' }],
    name: 'upgradePriceOracleFactory',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'pool', internalType: 'address', type: 'address' }],
    name: 'upgradeRateKeeperFactory',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'version',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'domain',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
      {
        name: 'peripheryContract',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'AddPeripheryContract',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'AddToken',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'factory',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'suite',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'target',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'AuthorizeFactory',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'creditManager',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'ConfigureCreditSuite',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'ConfigureInterestRateModel',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'ConfigureLossPolicy',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'ConfigurePool',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'ConfigurePriceOracle',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'ConfigureRateKeeper',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'creditManager',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'factory',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'CreateCreditSuite',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'priceOracle',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
      {
        name: 'interestRateModel',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
      {
        name: 'rateKeeper',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
      {
        name: 'lossPolicy',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
      {
        name: 'factories',
        internalType: 'struct MarketFactories',
        type: 'tuple',
        components: [
          { name: 'poolFactory', internalType: 'address', type: 'address' },
          {
            name: 'priceOracleFactory',
            internalType: 'address',
            type: 'address',
          },
          {
            name: 'interestRateModelFactory',
            internalType: 'address',
            type: 'address',
          },
          {
            name: 'rateKeeperFactory',
            internalType: 'address',
            type: 'address',
          },
          {
            name: 'lossPolicyFactory',
            internalType: 'address',
            type: 'address',
          },
        ],
        indexed: false,
      },
    ],
    name: 'CreateMarket',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'creditManager',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'EmergencyConfigureCreditSuite',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'EmergencyConfigureInterestRateModel',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'EmergencyConfigureLossPolicy',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'EmergencyConfigurePool',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'EmergencyConfigurePriceOracle',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      { name: 'data', internalType: 'bytes', type: 'bytes', indexed: false },
    ],
    name: 'EmergencyConfigureRateKeeper',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'role', internalType: 'bytes32', type: 'bytes32', indexed: true },
      {
        name: 'account',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'EmergencyRevokeRole',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'target',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'callData',
        internalType: 'bytes',
        type: 'bytes',
        indexed: false,
      },
    ],
    name: 'ExecuteHook',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'role', internalType: 'bytes32', type: 'bytes32', indexed: true },
      {
        name: 'account',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'GrantRole',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'domain',
        internalType: 'bytes32',
        type: 'bytes32',
        indexed: true,
      },
      {
        name: 'peripheryContract',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'RemovePeripheryContract',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'role', internalType: 'bytes32', type: 'bytes32', indexed: true },
      {
        name: 'account',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'RevokeRole',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'newEmergencyAdmin',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'SetEmergencyAdmin',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'creditManager',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'ShutdownCreditSuite',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
    ],
    name: 'ShutdownMarket',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'factory',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'suite',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'target',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'UnauthorizeFactory',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'interestRateModel',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'UpdateInterestRateModel',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'lossPolicy',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'UpdateLossPolicy',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'priceOracle',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'UpdatePriceOracle',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'rateKeeper',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'UpdateRateKeeper',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'creditManager',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'factory',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'UpgradeCreditFactory',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'factory',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'UpgradeInterestRateModelFactory',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'factory',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'UpgradeLossPolicyFactory',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'factory',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'UpgradePoolFactory',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'factory',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'UpgradePriceOracleFactory',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      { name: 'pool', internalType: 'address', type: 'address', indexed: true },
      {
        name: 'factory',
        internalType: 'address',
        type: 'address',
        indexed: false,
      },
    ],
    name: 'UpgradeRateKeeperFactory',
  },
  {
    type: 'error',
    inputs: [{ name: 'caller', internalType: 'address', type: 'address' }],
    name: 'CallerIsNotAdminException',
  },
  {
    type: 'error',
    inputs: [{ name: 'caller', internalType: 'address', type: 'address' }],
    name: 'CallerIsNotEmergencyAdminException',
  },
  {
    type: 'error',
    inputs: [{ name: 'caller', internalType: 'address', type: 'address' }],
    name: 'CallerIsNotSelfException',
  },
  {
    type: 'error',
    inputs: [
      { name: 'creditManager', internalType: 'address', type: 'address' },
    ],
    name: 'CreditSuiteNotRegisteredException',
  },
  {
    type: 'error',
    inputs: [
      { name: 'peripheryContract', internalType: 'address', type: 'address' },
    ],
    name: 'IncorrectPeripheryContractException',
  },
  {
    type: 'error',
    inputs: [{ name: 'pool', internalType: 'address', type: 'address' }],
    name: 'MarketNotRegisteredException',
  },
  {
    type: 'error',
    inputs: [
      { name: 'factory', internalType: 'address', type: 'address' },
      { name: 'target', internalType: 'address', type: 'address' },
    ],
    name: 'UnauthorizedFactoryException',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// IMarketConfiguratorFactory
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iMarketConfiguratorFactoryAbi = [
  {
    type: 'function',
    inputs: [
      { name: 'marketConfigurator', internalType: 'address', type: 'address' },
    ],
    name: 'addMarketConfigurator',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'addressProvider',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'bytecodeRepository',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'contractType',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'emergencyAdmin', internalType: 'address', type: 'address' },
      { name: 'adminFeeTreasury', internalType: 'address', type: 'address' },
      { name: 'curatorName', internalType: 'string', type: 'string' },
      { name: 'deployGovernor', internalType: 'bool', type: 'bool' },
    ],
    name: 'createMarketConfigurator',
    outputs: [
      { name: 'marketConfigurator', internalType: 'address', type: 'address' },
    ],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getMarketConfigurators',
    outputs: [{ name: '', internalType: 'address[]', type: 'address[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getShutdownMarketConfigurators',
    outputs: [{ name: '', internalType: 'address[]', type: 'address[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'account', internalType: 'address', type: 'address' }],
    name: 'isMarketConfigurator',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'marketConfigurator', internalType: 'address', type: 'address' },
    ],
    name: 'shutdownMarketConfigurator',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'version',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'marketConfigurator',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      { name: 'name', internalType: 'string', type: 'string', indexed: false },
    ],
    name: 'CreateMarketConfigurator',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'marketConfigurator',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'ShutdownMarketConfigurator',
  },
  {
    type: 'error',
    inputs: [{ name: 'addr', internalType: 'address', type: 'address' }],
    name: 'AddressIsNotMarketConfiguratorException',
  },
  {
    type: 'error',
    inputs: [{ name: 'caller', internalType: 'address', type: 'address' }],
    name: 'CallerIsNotCrossChainGovernanceException',
  },
  {
    type: 'error',
    inputs: [{ name: 'caller', internalType: 'address', type: 'address' }],
    name: 'CallerIsNotMarketConfiguratorAdminException',
  },
  {
    type: 'error',
    inputs: [{ name: 'caller', internalType: 'address', type: 'address' }],
    name: 'CallerIsNotMarketConfiguratorException',
  },
  {
    type: 'error',
    inputs: [],
    name: 'CantShutdownMarketConfiguratorException',
  },
  {
    type: 'error',
    inputs: [
      { name: 'marketConfigurator', internalType: 'address', type: 'address' },
    ],
    name: 'MarketConfiguratorIsAlreadyAddedException',
  },
  {
    type: 'error',
    inputs: [
      { name: 'marketConfigruator', internalType: 'address', type: 'address' },
    ],
    name: 'MarketConfiguratorIsAlreadyShutdownException',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// IPoolConfigureActions
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iPoolConfigureActionsAbi = [
  {
    type: 'function',
    inputs: [],
    name: 'pause',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'creditManager', internalType: 'address', type: 'address' },
      { name: 'limit', internalType: 'uint256', type: 'uint256' },
    ],
    name: 'setCreditManagerDebtLimit',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'limit', internalType: 'uint96', type: 'uint96' },
    ],
    name: 'setTokenLimit',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'fee', internalType: 'uint16', type: 'uint16' },
    ],
    name: 'setTokenQuotaIncreaseFee',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [{ name: 'limit', internalType: 'uint256', type: 'uint256' }],
    name: 'setTotalDebtLimit',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'unpause',
    outputs: [],
    stateMutability: 'nonpayable',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// IPriceFeedStore
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iPriceFeedStoreAbi = [
  {
    type: 'function',
    inputs: [
      { name: 'priceFeed', internalType: 'address', type: 'address' },
      { name: 'stalenessPeriod', internalType: 'uint32', type: 'uint32' },
      { name: 'name', internalType: 'string', type: 'string' },
    ],
    name: 'addPriceFeed',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'priceFeed', internalType: 'address', type: 'address' },
    ],
    name: 'allowPriceFeed',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'contractType',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'priceFeed', internalType: 'address', type: 'address' },
    ],
    name: 'forbidPriceFeed',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'priceFeed', internalType: 'address', type: 'address' },
    ],
    name: 'getAllowanceTimestamp',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getKnownPriceFeeds',
    outputs: [{ name: '', internalType: 'address[]', type: 'address[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getKnownTokens',
    outputs: [{ name: '', internalType: 'address[]', type: 'address[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'token', internalType: 'address', type: 'address' }],
    name: 'getPriceFeeds',
    outputs: [{ name: '', internalType: 'address[]', type: 'address[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'priceFeed', internalType: 'address', type: 'address' }],
    name: 'getStalenessPeriod',
    outputs: [{ name: '', internalType: 'uint32', type: 'uint32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getTokenPriceFeedsMap',
    outputs: [
      {
        name: '',
        internalType: 'struct ConnectedPriceFeed[]',
        type: 'tuple[]',
        components: [
          { name: 'token', internalType: 'address', type: 'address' },
          { name: 'priceFeeds', internalType: 'address[]', type: 'address[]' },
        ],
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'priceFeed', internalType: 'address', type: 'address' },
    ],
    name: 'isAllowedPriceFeed',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'owner',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'priceFeed', internalType: 'address', type: 'address' }],
    name: 'priceFeedInfo',
    outputs: [
      {
        name: '',
        internalType: 'struct PriceFeedInfo',
        type: 'tuple',
        components: [
          { name: 'author', internalType: 'address', type: 'address' },
          { name: 'name', internalType: 'string', type: 'string' },
          { name: 'stalenessPeriod', internalType: 'uint32', type: 'uint32' },
          { name: 'priceFeedType', internalType: 'bytes32', type: 'bytes32' },
          { name: 'version', internalType: 'uint256', type: 'uint256' },
        ],
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'priceFeed', internalType: 'address', type: 'address' },
      { name: 'stalenessPeriod', internalType: 'uint32', type: 'uint32' },
    ],
    name: 'setStalenessPeriod',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'version',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'priceFeed',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'stalenessPeriod',
        internalType: 'uint32',
        type: 'uint32',
        indexed: false,
      },
      { name: 'name', internalType: 'string', type: 'string', indexed: false },
    ],
    name: 'AddPriceFeed',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'priceFeed',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'AllowPriceFeed',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'priceFeed',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'ForbidPriceFeed',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'priceFeed',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      {
        name: 'stalenessPeriod',
        internalType: 'uint32',
        type: 'uint32',
        indexed: false,
      },
    ],
    name: 'SetStalenessPeriod',
  },
  {
    type: 'error',
    inputs: [{ name: 'caller', internalType: 'address', type: 'address' }],
    name: 'CallerIsNotOwnerException',
  },
  {
    type: 'error',
    inputs: [{ name: 'priceFeed', internalType: 'address', type: 'address' }],
    name: 'PriceFeedAlreadyAddedException',
  },
  {
    type: 'error',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'priceFeed', internalType: 'address', type: 'address' },
    ],
    name: 'PriceFeedIsNotAllowedException',
  },
  {
    type: 'error',
    inputs: [{ name: 'priceFeed', internalType: 'address', type: 'address' }],
    name: 'PriceFeedIsNotOwnedByStore',
  },
  {
    type: 'error',
    inputs: [{ name: 'priceFeed', internalType: 'address', type: 'address' }],
    name: 'PriceFeedNotKnownException',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// IPriceOracleConfigureActions
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iPriceOracleConfigureActionsAbi = [
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'priceFeed', internalType: 'address', type: 'address' },
    ],
    name: 'setPriceFeed',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'priceFeed', internalType: 'address', type: 'address' },
    ],
    name: 'setReservePriceFeed',
    outputs: [],
    stateMutability: 'nonpayable',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ITumblerV3
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iTumblerV3Abi = [
  {
    type: 'function',
    inputs: [],
    name: 'acl',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'token', internalType: 'address', type: 'address' }],
    name: 'addToken',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'contractType',
    outputs: [{ name: '', internalType: 'bytes32', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'epochLength',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'tokens', internalType: 'address[]', type: 'address[]' }],
    name: 'getRates',
    outputs: [{ name: '', internalType: 'uint16[]', type: 'uint16[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getTokens',
    outputs: [{ name: '', internalType: 'address[]', type: 'address[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [{ name: 'token', internalType: 'address', type: 'address' }],
    name: 'isTokenAdded',
    outputs: [{ name: '', internalType: 'bool', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'pool',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'poolQuotaKeeper',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [
      { name: 'token', internalType: 'address', type: 'address' },
      { name: 'rate', internalType: 'uint16', type: 'uint16' },
    ],
    name: 'setRate',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'underlying',
    outputs: [{ name: '', internalType: 'address', type: 'address' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'updateRates',
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    inputs: [],
    name: 'version',
    outputs: [{ name: '', internalType: 'uint256', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'AddToken',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      { name: 'rate', internalType: 'uint16', type: 'uint16', indexed: false },
    ],
    name: 'SetRate',
  },
]

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ITumblerV3Events
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iTumblerV3EventsAbi = [
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
    ],
    name: 'AddToken',
  },
  {
    type: 'event',
    anonymous: false,
    inputs: [
      {
        name: 'token',
        internalType: 'address',
        type: 'address',
        indexed: true,
      },
      { name: 'rate', internalType: 'uint16', type: 'uint16', indexed: false },
    ],
    name: 'SetRate',
  },
]
