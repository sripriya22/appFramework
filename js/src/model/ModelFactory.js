/**
 * @fileoverview ModelFactory creates dynamic model instances from projection maps.
 * Instances are pure data containers with metadata accessors for view generation.
 */

/** Primitive types that don't require nested instantiation */
const PRIMITIVE_TYPES = ['string', 'double', 'logical', 'number', 'boolean'];

/**
 * Checks if a type is a primitive type.
 * @param {string} type - The type name from the projection map
 * @returns {boolean} True if the type is primitive
 */
function isPrimitiveType(type) {
  return PRIMITIVE_TYPES.includes(type);
}

/**
 * Creates a model instance with data properties and metadata accessors.
 * @param {Object} projectionMap - The projection map defining the class structure
 * @param {Object} data - The data to populate the instance with
 * @param {ModelFactory} factory - The factory instance for recursive instantiation
 * @returns {Object} The model instance
 */
function createModelInstance(projectionMap, data, factory) {
  const instance = Object.create(null);
  
  for (const [propName, propDef] of Object.entries(projectionMap.Properties)) {
    const value = data[propName];
    instance[propName] = factory.instantiateProperty(value, propDef);
  }
  
  // Attach metadata accessors (non-enumerable to keep data clean)
  Object.defineProperties(instance, {
    getPropertyMetadata: {
      value: (propName) => {
        const meta = projectionMap.Properties[propName];
        if (!meta) {
          throw new Error(`Unknown property: ${propName}`);
        }
        return meta;
      },
      enumerable: false
    },
    getClassName: {
      value: () => projectionMap.JSClass,
      enumerable: false
    },
    getMATLABClass: {
      value: () => projectionMap.MATLABClass,
      enumerable: false
    },
    getAllPropertyNames: {
      value: () => Object.keys(projectionMap.Properties),
      enumerable: false
    },
    getReferenceIDProperty: {
      value: () => projectionMap.ReferenceIDProperty || null,
      enumerable: false
    }
  });
  
  return instance;
}

/**
 * Factory for creating dynamic model instances from projection maps.
 * Instances are pure data containers with metadata accessors.
 */
export class ModelFactory {
  /**
   * Creates a new ModelFactory.
   * @param {Object} projectionMaps - Map of MATLABClass name to projection map
   */
  constructor(projectionMaps) {
    if (!projectionMaps || typeof projectionMaps !== 'object') {
      throw new Error('ModelFactory requires a projectionMaps object');
    }
    this.maps = projectionMaps;
  }

  /**
   * Registers a projection map for a class.
   * @param {Object} projectionMap - The projection map to register
   */
  registerMap(projectionMap) {
    if (!projectionMap.MATLABClass) {
      throw new Error('Projection map must have MATLABClass property');
    }
    this.maps[projectionMap.MATLABClass] = projectionMap;
  }

  /**
   * Checks if a projection map exists for a class.
   * @param {string} className - The MATLAB class name
   * @returns {boolean} True if the map exists
   */
  hasMap(className) {
    return className in this.maps;
  }

  /**
   * Gets the projection map for a class.
   * @param {string} className - The MATLAB class name
   * @returns {Object} The projection map
   */
  getMap(className) {
    const map = this.maps[className];
    if (!map) {
      throw new Error(`No projection map for class: ${className}`);
    }
    return map;
  }

  /**
   * Creates a model instance from data.
   * @param {string} className - The MATLAB class name
   * @param {Object} data - The data to populate the instance with
   * @returns {Object} The model instance
   */
  create(className, data) {
    const map = this.getMap(className);
    
    if (data === null || data === undefined) {
      return data;
    }
    
    return createModelInstance(map, data, this);
  }

  /**
   * Instantiates a property value based on its definition.
   * Handles scalar/array normalization based on IsArray flag.
   * @param {*} value - The raw value
   * @param {Object} propDef - The property definition from the projection map
   * @returns {*} The instantiated value
   */
  instantiateProperty(value, propDef) {
    if (value === null || value === undefined) {
      return value;
    }
    
    // Normalize scalar/array based on IsArray flag
    value = this.normalizeArrayValue(value, propDef);
    
    // Reference properties stay as IDs (numbers or structs with ID properties)
    if (propDef.IsReference) {
      return value;
    }
    
    // Primitive types - return normalized value
    if (isPrimitiveType(propDef.Type)) {
      return value;
    }
    
    // Nested object type
    if (this.hasMap(propDef.Type)) {
      if (propDef.IsArray) {
        return value.map(v => this.create(propDef.Type, v));
      }
      return this.create(propDef.Type, value);
    }
    
    // Unknown non-primitive type without a map - error
    throw new Error(
      `Unknown type '${propDef.Type}' - not a primitive and no projection map registered`
    );
  }

  /**
   * Normalizes value to match IsArray expectation.
   * - If IsArray=true and value is scalar, wraps in array
   * - If IsArray=false and value is single-element array, unwraps
   * @param {*} value - The raw value
   * @param {Object} propDef - The property definition
   * @returns {*} The normalized value
   */
  normalizeArrayValue(value, propDef) {
    if (value === null || value === undefined) {
      return value;
    }
    
    const isArray = Array.isArray(value);
    const expectArray = propDef.IsArray === true;
    
    if (expectArray && !isArray) {
      // Wrap scalar in array
      return [value];
    }
    
    if (!expectArray && isArray) {
      if (value.length === 0) {
        throw new Error(
          'Property is defined as scalar (IsArray=false) but received empty array'
        );
      } else if (value.length === 1) {
        // Unwrap single-element array for scalar property
        return value[0];
      } else {
        throw new Error(
          `Property is defined as scalar (IsArray=false) but received array with ${value.length} elements`
        );
      }
    }
    
    return value;
  }
}

/**
 * Loads projection maps from an object where keys are filenames.
 * @param {Object} mapFiles - Object with filename keys and projection map values
 * @returns {Object} Map of MATLABClass name to projection map
 */
export function buildProjectionMapsFromFiles(mapFiles) {
  const maps = {};
  for (const projectionMap of Object.values(mapFiles)) {
    if (projectionMap.MATLABClass) {
      maps[projectionMap.MATLABClass] = projectionMap;
    }
  }
  return maps;
}
