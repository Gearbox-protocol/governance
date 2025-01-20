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
    name: 'DeployContact',
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
    name: 'getCurrentProposals',
    outputs: [
      {
        name: '',
        internalType: 'struct SignedProposal[]',
        type: 'tuple[]',
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
    name: 'getExecutedProposalHashes',
    outputs: [{ name: '', internalType: 'bytes32[]', type: 'bytes32[]' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    inputs: [],
    name: 'getExecutedProposals',
    outputs: [
      {
        name: '',
        internalType: 'struct SignedProposal[]',
        type: 'tuple[]',
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
    inputs: [
      { name: 'proposalHash', internalType: 'bytes32', type: 'bytes32' },
    ],
    name: 'getSignedProposal',
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
// IPriceFeedStore
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

export const iPriceFeedStoreAbi = [
  {
    type: 'function',
    inputs: [
      { name: 'priceFeed', internalType: 'address', type: 'address' },
      { name: 'stalenessPeriod', internalType: 'uint32', type: 'uint32' },
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
        indexed: false,
      },
      {
        name: 'stalenessPeriod',
        internalType: 'uint32',
        type: 'uint32',
        indexed: false,
      },
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
        indexed: false,
      },
      {
        name: 'priceFeed',
        internalType: 'address',
        type: 'address',
        indexed: false,
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
        indexed: false,
      },
      {
        name: 'priceFeed',
        internalType: 'address',
        type: 'address',
        indexed: false,
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
        indexed: false,
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
    name: 'PriceFeedNotKnownException',
  },
]
