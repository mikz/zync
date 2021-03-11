# frozen_string_literal: true

require 'test_helper'
require 'base64'

class Integration::KubernetesServiceTest < ActiveSupport::TestCase
  include Base64

  def before_setup
    @_env = ENV.to_hash
    super
  end

  def after_teardown
    ENV.replace(@_env)
    super
  end

  test 'create openshift route ' do
    ENV['KUBERNETES_NAMESPACE'] = 'zync'
    ENV['KUBE_TOKEN'] = strict_encode64('token')
    ENV['KUBE_SERVER'] = 'http://localhost'
    ENV['KUBE_CA'] = encode64 <<~CERTIFICATE
      -----BEGIN CERTIFICATE-----
      MIIBZjCCAQ2gAwIBAgIQBHMSmrmlj2QTqgFRa+HP3DAKBggqhkjOPQQDAjASMRAw
      DgYDVQQDEwdyb290LWNhMB4XDTE5MDQwNDExMzI1OVoXDTI5MDQwMTExMzI1OVow
      EjEQMA4GA1UEAxMHcm9vdC1jYTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABGG2
      NDgiBuXNVWVVxrDNVjPsKm14wg76w4830Zn3K24u03LJthzsB3RPJN9l+kM7ryjg
      dCenDYANVabMMQEy2iGjRTBDMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAG
      AQH/AgEBMB0GA1UdDgQWBBRfJt1t0sAlUMBwfeTWVv2v4XNcNjAKBggqhkjOPQQD
      AgNHADBEAiB+MlaTocrG33AiOE8TrH4N2gVrDBo2fAyJ1qDmjxhWvAIgPOoAoWQ9
      qwUVj52L6/Ptj0Tn4Mt6u+bdVr6jEXkZ8f0=
      -----END CERTIFICATE-----
    CERTIFICATE
    
    stub_request(:get, 'http://localhost/apis').
      with(
        headers: {
          'Accept'=>'application/json',
          'Authorization'=>'Bearer token',
        }).
      to_return(status: 200, body: {
        kind: "APIGroupList",
        apiVersion: "v1",
        groups: [
          { name: "networking.k8s.io", versions: [{ groupVersion: "networking.k8s.io/v1", version: "v1" }], preferredVersion: { groupVersion: "networking.k8s.io/v1", version: "v1" } },
          { name: "route.openshift.io", versions: [{ groupVersion: "route.openshift.io/v1", version: "v1" }], preferredVersion: { groupVersion: "route.openshift.io/v1", version: "v1" } },
        ]
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    service = Integration::KubernetesService.new(nil)

    proxy = entries(:proxy)

    stub_request(:get, 'http://localhost/apis/route.openshift.io/v1').
      with(
        headers: {
          'Accept'=>'application/json',
          'Authorization'=>'Bearer token',
        }).
      to_return(status: 200, body: {
        kind: "APIResourceList",
        apiVersion: "v1",
        groupVersion: "route.openshift.io/v1",
        resources: [
          { name: "routes", singularName: "", namespaced: true, kind: "Route", verbs: %w(create delete deletecollection get list patch update watch), categories: ["all"] },
        ]
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, 'http://localhost/apis/route.openshift.io/v1/namespaces/zync/routes?labelSelector=3scale.net/created-by=zync,3scale.net/tenant_id=298486374,zync.3scale.net/record=Z2lkOi8venluYy9Qcm94eS8yOTg0ODYzNzQ,zync.3scale.net/ingress=proxy,3scale.net/service_id=2').
      with(
        headers: {
          'Accept'=>'application/json',
          'Authorization'=>'Bearer token',
        }).
      to_return(status: 200, body: {
        kind: 'RouteList',
        apiVersion: 'route.openshift.io/v1',
        metadata: { selfLink: '/apis/route.openshift.io/v1/namespaces/zync/routes', resourceVersion: '651341' },
        items: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    service.call(proxy)
  end

  test 'create native ingress when not in openshift' do
    ENV['KUBERNETES_NAMESPACE'] = 'zync'
    ENV['KUBE_TOKEN'] = strict_encode64('token')
    ENV['KUBE_SERVER'] = 'http://localhost'
    ENV['KUBE_CA'] = encode64 <<~CERTIFICATE
      -----BEGIN CERTIFICATE-----
      MIIBZjCCAQ2gAwIBAgIQBHMSmrmlj2QTqgFRa+HP3DAKBggqhkjOPQQDAjASMRAw
      DgYDVQQDEwdyb290LWNhMB4XDTE5MDQwNDExMzI1OVoXDTI5MDQwMTExMzI1OVow
      EjEQMA4GA1UEAxMHcm9vdC1jYTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABGG2
      NDgiBuXNVWVVxrDNVjPsKm14wg76w4830Zn3K24u03LJthzsB3RPJN9l+kM7ryjg
      dCenDYANVabMMQEy2iGjRTBDMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAG
      AQH/AgEBMB0GA1UdDgQWBBRfJt1t0sAlUMBwfeTWVv2v4XNcNjAKBggqhkjOPQQD
      AgNHADBEAiB+MlaTocrG33AiOE8TrH4N2gVrDBo2fAyJ1qDmjxhWvAIgPOoAoWQ9
      qwUVj52L6/Ptj0Tn4Mt6u+bdVr6jEXkZ8f0=
      -----END CERTIFICATE-----
    CERTIFICATE

    stub_request(:get, 'http://localhost/apis').
      with(
        headers: {
          'Accept'=>'application/json',
          'Authorization'=>'Bearer token',
        }).
      to_return(status: 200, body: {
        kind: "APIGroupList",
        apiVersion: "v1",
        groups: [
          { name: "networking.k8s.io", versions: [{ groupVersion: "networking.k8s.io/v1", version: "v1" }], preferredVersion: { groupVersion: "networking.k8s.io/v1", version: "v1" } },
        ]
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    service = Integration::KubernetesService.new(nil)

    proxy = entries(:proxy)

    stub_request(:get, 'http://localhost/apis/networking.k8s.io/v1').
      with(
        headers: {
          'Accept'=>'application/json',
          'Authorization'=>'Bearer token',
        }).
      to_return(status: 200, body: {
        kind: "APIResourceList",
        apiVersion: "v1",
        groupVersion: "networking.k8s.io/v1",
        resources: [
          { name: "ingressclasses", singularName: "", namespaced: false, kind: "IngressClass", verbs: ["create","delete","deletecollection","get","list","patch","update","watch"], storageVersionHash: "6upRfBq0FOI=" },
          { name: "ingresses", singularName: "", namespaced: true, kind: "Ingress", verbs: ["create","delete","deletecollection","get","list","patch","update","watch"], shortNames: ["ing"], storageVersionHash: "ZOAfGflaKd0=" }, 
          { name: "ingresses/status", singularName: "", namespaced:true, kind: "Ingress", verbs: ["get","patch","update"] }, 
          { name: "networkpolicies", singularName: "", namespaced: true, kind: "NetworkPolicy", verbs: ["create","delete","deletecollection","get","list","patch","update","watch"], shortNames: ["netpol"], storageVersionHash: "YpfwF18m1G8=" },
        ]
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, 'http://localhost/apis/networking.k8s.io/v1/namespaces/zync/ingresses?labelSelector=3scale.net/created-by=zync,3scale.net/tenant_id=298486374,zync.3scale.net/record=Z2lkOi8venluYy9Qcm94eS8yOTg0ODYzNzQ,zync.3scale.net/ingress=proxy,3scale.net/service_id=2').
      with(
        headers: {
          'Accept'=>'application/json',
          'Authorization'=>'Bearer token',
        }).
      to_return(status: 200, body: {
        kind: 'IngressList',
        apiVersion: 'networking.k8s.io/v1',
        metadata: { selfLink: '/apis/networking.k8s.io/v1/namespaces/zync/ingresses', resourceVersion: '651341' },
        items: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    service.call(proxy)
  end

  
  class RouteSpec < ActiveSupport::TestCase
    test 'secure routes' do
      url = 'https://my-api.example.com'
      service_name = 'My API'
      port = 7443
      spec = Integration::KubernetesService::RouteSpec.new(url, service_name, port)
      json = {
        host: "my-api.example.com",
        port: {targetPort: 7443},
        to: {kind: "Service", name: "My API"},
        tls: {insecureEdgeTerminationPolicy: "Redirect", termination: "edge"}
      }
      assert_equal json, spec.to_hash

      url = 'http://my-api.example.com'
      service_name = 'My API'
      port = 7780
      spec = Integration::KubernetesService::RouteSpec.new(url, service_name, port)
      json = {
        host: "my-api.example.com",
        port: {targetPort: 7780},
        to: {kind: "Service", name: "My API"},
        tls: nil
      }
      assert_equal json, spec.to_hash
    end

    test 'defaults to https when scheme is missing' do
      url = 'my-api.example.com'
      service_name = 'My API'
      port = 7443
      spec = Integration::KubernetesService::RouteSpec.new(url, service_name, port)
      json = {
        host: "my-api.example.com",
        port: {targetPort: 7443},
        to: {kind: "Service", name: "My API"},
        tls: {insecureEdgeTerminationPolicy: "Redirect", termination: "edge"}
      }
      assert_equal json, spec.to_hash
    end
  end

  class IngressSpec < ActiveSupport::TestCase
    test 'secure ingresses' do
      url = 'https://my-api.example.com'
      service_name = 'My API'
      port = 7443
      tenant_id = '2'
      spec = Integration::KubernetesService::IngressSpec.new(url, service_name, port, tenant_id)
      json = {
        rules: [{
          host: "my-api.example.com",
          http: {
            paths: [{ path: '/', pathType: 'Prefix', backend: { service: { name: service_name, port: { name: port } } } }]
          }
        }],
        tls: [{hosts: ["my-api.example.com"], secretName: "My API-tls-2"}]
      }
      assert_equal json, spec.to_hash

      url = 'http://my-api.example.com'
      service_name = 'My API'
      port = 7780
      tenant_id = '2'
      spec = Integration::KubernetesService::IngressSpec.new(url, service_name, port, tenant_id)
      json = {
        rules: [{
          host: "my-api.example.com",
          http: {
            paths: [{ path: '/', pathType: 'Prefix', backend: { service: { name: service_name, port: { name: port } } } }]
          }
        }],
        tls: nil
      }
      assert_equal json, spec.to_hash
    end

    test 'defaults to https when scheme is missing' do
      url = 'my-api.example.com'
      service_name = 'My API'
      port = 7443
      tenant_id = '2'
      spec = Integration::KubernetesService::IngressSpec.new(url, service_name, port, tenant_id)
      json = {
        rules: [{
          host: "my-api.example.com",
          http: {
            paths: [{ path: '/', pathType: 'Prefix', backend: { service: { name: service_name, port: { name: port } } } }]
          }
        }],
        tls: [{hosts: ["my-api.example.com"], secretName: "My API-tls-2"}]
      }
      assert_equal json, spec.to_hash
    end
  end
end
