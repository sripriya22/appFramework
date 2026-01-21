/**
 * @fileoverview Unit tests for ModelFactory
 * Run with: node --experimental-vm-modules js/test/ModelFactoryTest.js
 */

import { ModelFactory, buildProjectionMapsFromFiles } from '../src/model/ModelFactory.js';

// Simple assertion helpers
let testCount = 0;
let passCount = 0;

function assertEqual(actual, expected, message) {
  testCount++;
  if (actual === expected) {
    passCount++;
    console.log(`  ✓ ${message}`);
  } else {
    console.log(`  ✗ ${message}`);
    console.log(`    Expected: ${JSON.stringify(expected)}`);
    console.log(`    Actual:   ${JSON.stringify(actual)}`);
  }
}

function assertDeepEqual(actual, expected, message) {
  testCount++;
  if (JSON.stringify(actual) === JSON.stringify(expected)) {
    passCount++;
    console.log(`  ✓ ${message}`);
  } else {
    console.log(`  ✗ ${message}`);
    console.log(`    Expected: ${JSON.stringify(expected)}`);
    console.log(`    Actual:   ${JSON.stringify(actual)}`);
  }
}

function assertTrue(actual, message) {
  assertEqual(actual, true, message);
}

function assertFalse(actual, message) {
  assertEqual(actual, false, message);
}

function assertThrows(fn, expectedMessage, message) {
  testCount++;
  try {
    fn();
    console.log(`  ✗ ${message} - Expected error but none thrown`);
  } catch (e) {
    if (expectedMessage && !e.message.includes(expectedMessage)) {
      console.log(`  ✗ ${message}`);
      console.log(`    Expected error containing: ${expectedMessage}`);
      console.log(`    Actual error: ${e.message}`);
    } else {
      passCount++;
      console.log(`  ✓ ${message}`);
    }
  }
}

// Test projection maps
const simpleAnalysisMap = {
  MATLABClass: 'Test.Analysis',
  JSClass: 'Analysis',
  Properties: {
    StartTime: { Type: 'double' },
    StopTime: { Type: 'double' },
    Name: { Type: 'string', ReadOnly: true }
  }
};

const simpleSpeciesMap = {
  MATLABClass: 'Test.Species',
  JSClass: 'Species',
  ReferenceIDProperty: 'SessionID',
  Properties: {
    SessionID: { Type: 'double', ReadOnly: true },
    Name: { Type: 'string', ReadOnly: true },
    Value: { Type: 'double' },
    Units: { Type: 'string', ReadOnly: true }
  }
};

const simpleModelMap = {
  MATLABClass: 'Test.Model',
  JSClass: 'Model',
  Properties: {
    Name: { Type: 'string', ReadOnly: true },
    Species: { Type: 'Test.Species', IsArray: true, IsReference: false }
  }
};

const nestedAnalysisMap = {
  MATLABClass: 'Test.NestedAnalysis',
  JSClass: 'NestedAnalysis',
  Properties: {
    StartTime: { Type: 'double' },
    StopTime: { Type: 'double' },
    ModelObj: { Type: 'Test.Model', IsReference: false, ReadOnly: true },
    SelectedSpecies: { Type: 'Test.Species', IsArray: true, IsReference: true }
  }
};

// Tests
console.log('\n=== ModelFactory Tests ===\n');

console.log('Construction:');
{
  const maps = { 'Test.Analysis': simpleAnalysisMap };
  const factory = new ModelFactory(maps);
  assertTrue(factory.hasMap('Test.Analysis'), 'hasMap returns true for registered class');
  assertFalse(factory.hasMap('Unknown.Class'), 'hasMap returns false for unknown class');
  assertThrows(() => new ModelFactory(), 'projectionMaps object', 'throws without maps');
  assertThrows(() => new ModelFactory(null), 'projectionMaps object', 'throws with null');
}

console.log('\nSimple Instance Creation:');
{
  const maps = { 'Test.Analysis': simpleAnalysisMap };
  const factory = new ModelFactory(maps);
  
  const data = { StartTime: 0, StopTime: 100, Name: 'Test' };
  const instance = factory.create('Test.Analysis', data);
  
  assertEqual(instance.StartTime, 0, 'StartTime property set correctly');
  assertEqual(instance.StopTime, 100, 'StopTime property set correctly');
  assertEqual(instance.Name, 'Test', 'Name property set correctly');
}

console.log('\nMetadata Accessors:');
{
  const maps = { 'Test.Analysis': simpleAnalysisMap };
  const factory = new ModelFactory(maps);
  
  const data = { StartTime: 0, StopTime: 100, Name: 'Test' };
  const instance = factory.create('Test.Analysis', data);
  
  assertEqual(instance.getClassName(), 'Analysis', 'getClassName returns JSClass');
  assertEqual(instance.getMATLABClass(), 'Test.Analysis', 'getMATLABClass returns MATLABClass');
  assertDeepEqual(instance.getAllPropertyNames(), ['StartTime', 'StopTime', 'Name'], 'getAllPropertyNames returns property names');
  
  const startTimeMeta = instance.getPropertyMetadata('StartTime');
  assertEqual(startTimeMeta.Type, 'double', 'getPropertyMetadata returns Type');
  
  const nameMeta = instance.getPropertyMetadata('Name');
  assertEqual(nameMeta.ReadOnly, true, 'getPropertyMetadata returns ReadOnly');
  
  assertThrows(() => instance.getPropertyMetadata('Unknown'), 'Unknown property', 'throws for unknown property');
}

console.log('\nMetadata Accessors Not Enumerable:');
{
  const maps = { 'Test.Analysis': simpleAnalysisMap };
  const factory = new ModelFactory(maps);
  
  const data = { StartTime: 0, StopTime: 100, Name: 'Test' };
  const instance = factory.create('Test.Analysis', data);
  
  const keys = Object.keys(instance);
  assertDeepEqual(keys, ['StartTime', 'StopTime', 'Name'], 'Only data properties are enumerable');
  assertFalse(keys.includes('getClassName'), 'getClassName is not enumerable');
  assertFalse(keys.includes('getPropertyMetadata'), 'getPropertyMetadata is not enumerable');
}

console.log('\nNested Object Instantiation:');
{
  const maps = {
    'Test.NestedAnalysis': nestedAnalysisMap,
    'Test.Model': simpleModelMap,
    'Test.Species': simpleSpeciesMap
  };
  const factory = new ModelFactory(maps);
  
  const data = {
    StartTime: 0,
    StopTime: 100,
    ModelObj: {
      Name: 'TwoCompPK',
      Species: [
        { SessionID: 1, Name: 'Drug_Central', Value: 0, Units: 'mg' },
        { SessionID: 2, Name: 'Drug_Peripheral', Value: 0, Units: 'mg' }
      ]
    },
    SelectedSpecies: [1, 2]
  };
  
  const instance = factory.create('Test.NestedAnalysis', data);
  
  assertEqual(instance.StartTime, 0, 'Top-level property set');
  assertEqual(instance.ModelObj.Name, 'TwoCompPK', 'Nested object property accessible');
  assertEqual(instance.ModelObj.getClassName(), 'Model', 'Nested object has metadata');
  assertEqual(instance.ModelObj.Species.length, 2, 'Nested array has correct length');
  assertEqual(instance.ModelObj.Species[0].Name, 'Drug_Central', 'Nested array item property accessible');
  assertEqual(instance.ModelObj.Species[0].getClassName(), 'Species', 'Nested array item has metadata');
}

console.log('\nReference Properties Stay as IDs:');
{
  const maps = {
    'Test.NestedAnalysis': nestedAnalysisMap,
    'Test.Model': simpleModelMap,
    'Test.Species': simpleSpeciesMap
  };
  const factory = new ModelFactory(maps);
  
  const data = {
    StartTime: 0,
    StopTime: 100,
    ModelObj: { Name: 'Model', Species: [] },
    SelectedSpecies: [1, 2, 3]
  };
  
  const instance = factory.create('Test.NestedAnalysis', data);
  
  assertDeepEqual(instance.SelectedSpecies, [1, 2, 3], 'Reference array stays as IDs');
  assertEqual(typeof instance.SelectedSpecies[0], 'number', 'Reference ID is a number');
}

console.log('\nReferenceIDProperty:');
{
  const maps = { 'Test.Species': simpleSpeciesMap };
  const factory = new ModelFactory(maps);
  
  const data = { SessionID: 42, Name: 'Drug', Value: 10, Units: 'mg' };
  const instance = factory.create('Test.Species', data);
  
  assertEqual(instance.getReferenceIDProperty(), 'SessionID', 'getReferenceIDProperty returns correct property');
}

console.log('\nNull/Undefined Handling:');
{
  const maps = { 'Test.Analysis': simpleAnalysisMap };
  const factory = new ModelFactory(maps);
  
  const result1 = factory.create('Test.Analysis', null);
  assertEqual(result1, null, 'create with null returns null');
  
  const result2 = factory.create('Test.Analysis', undefined);
  assertEqual(result2, undefined, 'create with undefined returns undefined');
  
  const data = { StartTime: 0, StopTime: null, Name: undefined };
  const instance = factory.create('Test.Analysis', data);
  assertEqual(instance.StopTime, null, 'null property value preserved');
  assertEqual(instance.Name, undefined, 'undefined property value preserved');
}

console.log('\nError Cases:');
{
  const maps = { 'Test.Analysis': simpleAnalysisMap };
  const factory = new ModelFactory(maps);
  
  assertThrows(() => factory.create('Unknown.Class', {}), 'No projection map', 'throws for unknown class');
  assertThrows(() => factory.getMap('Unknown.Class'), 'No projection map', 'getMap throws for unknown class');
}

console.log('\nRegisterMap:');
{
  const factory = new ModelFactory({});
  assertFalse(factory.hasMap('Test.Analysis'), 'Initially has no map');
  
  factory.registerMap(simpleAnalysisMap);
  assertTrue(factory.hasMap('Test.Analysis'), 'Map registered successfully');
  
  const instance = factory.create('Test.Analysis', { StartTime: 0, StopTime: 100, Name: 'Test' });
  assertEqual(instance.StartTime, 0, 'Can create from registered map');
  
  assertThrows(() => factory.registerMap({}), 'MATLABClass property', 'throws for map without MATLABClass');
}

console.log('\nIsArray Normalization - Wrap Scalar in Array:');
{
  const mapWithArray = {
    MATLABClass: 'Test.ArrayTest',
    JSClass: 'ArrayTest',
    Properties: {
      Values: { Type: 'double', IsArray: true },
      Names: { Type: 'string', IsArray: true }
    }
  };
  const factory = new ModelFactory({ 'Test.ArrayTest': mapWithArray });
  
  // Scalar should be wrapped in array when IsArray=true
  const data = { Values: 42, Names: 'single' };
  const instance = factory.create('Test.ArrayTest', data);
  
  assertTrue(Array.isArray(instance.Values), 'Scalar number wrapped in array');
  assertDeepEqual(instance.Values, [42], 'Wrapped array contains correct value');
  assertTrue(Array.isArray(instance.Names), 'Scalar string wrapped in array');
  assertDeepEqual(instance.Names, ['single'], 'Wrapped string array contains correct value');
}

console.log('\nIsArray Normalization - Unwrap Single-Element Array:');
{
  const mapWithScalar = {
    MATLABClass: 'Test.ScalarTest',
    JSClass: 'ScalarTest',
    Properties: {
      Value: { Type: 'double', IsArray: false },
      Name: { Type: 'string', IsArray: false }
    }
  };
  const factory = new ModelFactory({ 'Test.ScalarTest': mapWithScalar });
  
  // Single-element array should be unwrapped when IsArray=false
  const data = { Value: [42], Name: ['single'] };
  const instance = factory.create('Test.ScalarTest', data);
  
  assertFalse(Array.isArray(instance.Value), 'Single-element number array unwrapped');
  assertEqual(instance.Value, 42, 'Unwrapped value is correct');
  assertFalse(Array.isArray(instance.Name), 'Single-element string array unwrapped');
  assertEqual(instance.Name, 'single', 'Unwrapped string is correct');
}

console.log('\nIsArray Normalization - Error on Multi-Element Array for Scalar:');
{
  const mapWithScalar = {
    MATLABClass: 'Test.ScalarTest',
    JSClass: 'ScalarTest',
    Properties: {
      Value: { Type: 'double', IsArray: false }
    }
  };
  const factory = new ModelFactory({ 'Test.ScalarTest': mapWithScalar });
  
  // Multi-element array should throw for scalar property
  const data = { Value: [1, 2, 3] };
  assertThrows(
    () => factory.create('Test.ScalarTest', data),
    'scalar',
    'Throws when multi-element array passed to scalar property'
  );
}

console.log('\nIsArray Normalization - Array Stays as Array:');
{
  const mapWithArray = {
    MATLABClass: 'Test.ArrayTest',
    JSClass: 'ArrayTest',
    Properties: {
      Values: { Type: 'double', IsArray: true }
    }
  };
  const factory = new ModelFactory({ 'Test.ArrayTest': mapWithArray });
  
  // Array should stay as array when IsArray=true
  const data = { Values: [1, 2, 3] };
  const instance = factory.create('Test.ArrayTest', data);
  
  assertTrue(Array.isArray(instance.Values), 'Array stays as array');
  assertDeepEqual(instance.Values, [1, 2, 3], 'Array values preserved');
}

console.log('\nPrimitive Array Types:');
{
  const mapWithPrimitiveArrays = {
    MATLABClass: 'Test.PrimitiveArrays',
    JSClass: 'PrimitiveArrays',
    Properties: {
      Numbers: { Type: 'double', IsArray: true },
      Strings: { Type: 'string', IsArray: true },
      Flags: { Type: 'logical', IsArray: true }
    }
  };
  const factory = new ModelFactory({ 'Test.PrimitiveArrays': mapWithPrimitiveArrays });
  
  const data = {
    Numbers: [1, 2, 3],
    Strings: ['a', 'b', 'c'],
    Flags: [true, false, true]
  };
  const instance = factory.create('Test.PrimitiveArrays', data);
  
  assertDeepEqual(instance.Numbers, [1, 2, 3], 'Number array preserved');
  assertDeepEqual(instance.Strings, ['a', 'b', 'c'], 'String array preserved');
  assertDeepEqual(instance.Flags, [true, false, true], 'Boolean array preserved');
}

console.log('\nIsArray Normalization - Error on Empty Array for Scalar:');
{
  const mapWithScalar = {
    MATLABClass: 'Test.ScalarTest',
    JSClass: 'ScalarTest',
    Properties: {
      Value: { Type: 'double', IsArray: false }
    }
  };
  const factory = new ModelFactory({ 'Test.ScalarTest': mapWithScalar });
  
  // Empty array should throw for scalar property
  const data = { Value: [] };
  assertThrows(
    () => factory.create('Test.ScalarTest', data),
    'empty array',
    'Throws when empty array passed to scalar property'
  );
}

console.log('\nUnknown Type Error:');
{
  const mapWithUnknownType = {
    MATLABClass: 'Test.UnknownType',
    JSClass: 'UnknownType',
    Properties: {
      CustomObj: { Type: 'SomeUnregisteredType', IsArray: false }
    }
  };
  const factory = new ModelFactory({ 'Test.UnknownType': mapWithUnknownType });
  
  // Unknown non-primitive type without a map should throw
  const data = { CustomObj: { foo: 'bar' } };
  assertThrows(
    () => factory.create('Test.UnknownType', data),
    'Unknown type',
    'Throws for unknown non-primitive type without projection map'
  );
}

console.log('\nUnknown Type Error - Array:');
{
  const mapWithUnknownArrayType = {
    MATLABClass: 'Test.UnknownArrayType',
    JSClass: 'UnknownArrayType',
    Properties: {
      Items: { Type: 'SomeUnregisteredType', IsArray: true }
    }
  };
  const factory = new ModelFactory({ 'Test.UnknownArrayType': mapWithUnknownArrayType });
  
  // Unknown non-primitive type without a map should throw even for arrays
  const data = { Items: [{ foo: 'bar' }] };
  assertThrows(
    () => factory.create('Test.UnknownArrayType', data),
    'Unknown type',
    'Throws for unknown array type without projection map'
  );
}

console.log('\nbuildProjectionMapsFromFiles:');
{
  const files = {
    'analysis.json': simpleAnalysisMap,
    'species.json': simpleSpeciesMap
  };
  
  const maps = buildProjectionMapsFromFiles(files);
  
  assertTrue('Test.Analysis' in maps, 'Analysis map indexed by MATLABClass');
  assertTrue('Test.Species' in maps, 'Species map indexed by MATLABClass');
  assertEqual(maps['Test.Analysis'].JSClass, 'Analysis', 'Map content preserved');
}

// Summary
console.log('\n=== Test Summary ===');
console.log(`Passed: ${passCount}/${testCount}`);

if (passCount === testCount) {
  console.log('All tests passed! ✓\n');
  process.exit(0);
} else {
  console.log(`${testCount - passCount} test(s) failed.\n`);
  process.exit(1);
}
